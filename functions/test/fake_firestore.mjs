/**
 * Minimal in-memory Firestore stand-in for unit tests.
 * Supports collection/doc get/set/merge and runTransaction with
 * optimistic concurrency (retry on conflicting writes).
 * Never connects to production.
 */
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

function isServerTimestamp(value) {
  try {
    return (
      value != null &&
      typeof value.isEqual === 'function' &&
      value.isEqual(FieldValue.serverTimestamp())
    );
  } catch {
    return false;
  }
}

function isDeleteValue(value) {
  try {
    return (
      value != null &&
      typeof value.isEqual === 'function' &&
      value.isEqual(FieldValue.delete())
    );
  } catch {
    return false;
  }
}

function setDotted(target, path, value) {
  const parts = path.split('.');
  let cursor = target;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const key = parts[i];
    if (!cursor[key] || typeof cursor[key] !== 'object' || Array.isArray(cursor[key])) {
      cursor[key] = {};
    }
    cursor = cursor[key];
  }
  cursor[parts[parts.length - 1]] = value;
}

function deleteDotted(target, path) {
  const parts = path.split('.');
  let cursor = target;
  for (let i = 0; i < parts.length - 1; i += 1) {
    const key = parts[i];
    if (!cursor[key] || typeof cursor[key] !== 'object') return;
    cursor = cursor[key];
  }
  delete cursor[parts[parts.length - 1]];
}

function applyUpdate(existing, incoming, now) {
  const out = { ...(existing || {}) };
  for (const [key, value] of Object.entries(incoming || {})) {
    if (isDeleteValue(value)) {
      if (key.includes('.')) deleteDotted(out, key);
      else delete out[key];
      continue;
    }
    const materialized = materialize(value, now);
    if (key.includes('.')) setDotted(out, key, materialized);
    else out[key] = materialized;
  }
  return out;
}

function materialize(value, now) {
  if (isServerTimestamp(value)) {
    return Timestamp.fromDate(now);
  }
  if (Array.isArray(value)) {
    return value.map((v) => materialize(v, now));
  }
  if (value && typeof value === 'object' && !(value instanceof Timestamp)) {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = materialize(v, now);
    }
    return out;
  }
  return value;
}

function deepMerge(target, source) {
  const out = { ...(target || {}) };
  for (const [k, v] of Object.entries(source || {})) {
    if (
      v &&
      typeof v === 'object' &&
      !(v instanceof Timestamp) &&
      !isServerTimestamp(v) &&
      !Array.isArray(v)
    ) {
      out[k] = deepMerge(out[k], v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

class FakeDocSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this._data = data;
  }
  get exists() {
    return this._data != null;
  }
  data() {
    return this._data == null ? undefined : { ...this._data };
  }
  get path() {
    return this.ref.path;
  }
}

class FakeDocRef {
  constructor(db, path) {
    this.db = db;
    this.path = path;
  }
  async get() {
    return new FakeDocSnapshot(this, this.db._store.get(this.path) ?? null);
  }
  async set(data, options = {}) {
    const now = this.db._now();
    const incoming = materialize(data, now);
    if (options.merge) {
      const existing = this.db._store.get(this.path) ?? {};
      this.db._store.set(this.path, deepMerge(existing, incoming));
    } else {
      this.db._store.set(this.path, incoming);
    }
    this.db._bumpVersion(this.path);
  }
  async update(data) {
    const existing = this.db._store.get(this.path);
    if (!existing) {
      const error = new Error(`No document to update: ${this.path}`);
      error.code = 'not-found';
      throw error;
    }
    this.db._store.set(this.path, applyUpdate(existing, data, this.db._now()));
    this.db._bumpVersion(this.path);
  }
  async create(data) {
    if (this.db._store.has(this.path)) {
      const error = new Error(`Document already exists: ${this.path}`);
      error.code = 'already-exists';
      throw error;
    }
    await this.set(data);
  }
  async delete() {
    this.db._store.delete(this.path);
    this.db._bumpVersion(this.path);
  }
  collection(name) {
    return new FakeCollectionRef(this.db, `${this.path}/${name}`);
  }
}

class FakeCollectionRef {
  constructor(db, path) {
    this.db = db;
    this.path = path;
  }
  doc(id) {
    return new FakeDocRef(this.db, `${this.path}/${id}`);
  }
}

class FakeTransaction {
  constructor(db) {
    this.db = db;
    this._writes = [];
    this._readVersions = new Map();
  }
  async get(ref) {
    this._readVersions.set(ref.path, this.db._version(ref.path));
    return ref.get();
  }
  set(ref, data, options = {}) {
    this._writes.push({ type: 'set', ref, data, options });
  }
  update(ref, data) {
    this._writes.push({ type: 'update', ref, data });
  }
  /**
   * Apply buffered writes. Must be called under the store commit lock.
   * @returns {boolean} true if committed; false if read-set conflict
   */
  _tryCommitLocked() {
    for (const [path, version] of this._readVersions.entries()) {
      if (this.db._version(path) !== version) {
        return false;
      }
    }
    for (const write of this._writes) {
      const now = this.db._now();
      if (write.type === 'update') {
        const existing = this.db._store.get(write.ref.path);
        if (!existing) return false;
        this.db._store.set(
          write.ref.path,
          applyUpdate(existing, write.data, now),
        );
        this.db._bumpVersion(write.ref.path);
        continue;
      }
      const incoming = materialize(write.data, now);
      if (write.options?.merge) {
        const existing = this.db._store.get(write.ref.path) ?? {};
        this.db._store.set(write.ref.path, deepMerge(existing, incoming));
      } else {
        this.db._store.set(write.ref.path, incoming);
      }
      this.db._bumpVersion(write.ref.path);
    }
    return true;
  }
}

export class FakeFirestore {
  constructor({ now = () => new Date() } = {}) {
    this._store = new Map();
    this._versions = new Map();
    this._now = now;
    this._commitChain = Promise.resolve();
  }

  _version(path) {
    return this._versions.get(path) || 0;
  }

  _bumpVersion(path) {
    this._versions.set(path, this._version(path) + 1);
  }

  collection(name) {
    return new FakeCollectionRef(this, name);
  }

  doc(path) {
    return new FakeDocRef(this, path);
  }

  /**
   * Concurrent-safe transactions:
   * - updateFunction may run concurrently across callers
   * - commit validation + writes are serialized
   * - conflicting read sets cause retry (Firestore-like)
   */
  async runTransaction(updateFunction, { maxAttempts = 8 } = {}) {
    let lastError = null;
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const tx = new FakeTransaction(this);
      const result = await updateFunction(tx);

      const committed = await new Promise((resolve, reject) => {
        this._commitChain = this._commitChain
          .then(() => {
            resolve(tx._tryCommitLocked());
          })
          .catch(reject);
      });

      if (committed) return result;
      lastError = new Error('Transaction contention');
      // Yield so competing commits can land before retry.
      await Promise.resolve();
    }
    const error = lastError || new Error('Transaction failed due to contention');
    error.code = 'aborted';
    throw error;
  }
}
