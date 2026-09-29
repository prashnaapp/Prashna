import test from 'node:test';
import assert from 'node:assert/strict';
import { prefixesForQuestion, needsPrefixBackfill } from './question_search_prefixes_dry_run.mjs';

const sentence = 'On which date was the Constitution of India adopted?';

test('date and constitution match anywhere', () => {
  const prefixes = prefixesForQuestion(sentence);
  assert.ok(prefixes.includes('date'));
  assert.ok(prefixes.includes('constitution'));
  assert.ok(prefixes.includes('on'));
  assert.equal(new Set(prefixes).size, prefixes.length);
});

test('mini-constitution produces mini', () => {
  assert.ok(prefixesForQuestion('Mini-Constitution').includes('mini'));
});

test('missing or different prefixes require backfill', () => {
  const data = { question: sentence };
  assert.equal(needsPrefixBackfill(data), true);
  data.questionSearchPrefixes = prefixesForQuestion(sentence);
  data.questionSearchText = sentence.toLowerCase();
  assert.equal(needsPrefixBackfill(data), false);
  data.questionSearchPrefixes = ['date'];
  assert.equal(needsPrefixBackfill(data), true);
});
