/**
 * Google Play Developer API client for one-time product purchases.
 *
 * Credentials: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (JSON string) or
 * GOOGLE_APPLICATION_CREDENTIALS pointing to a service account with
 * Android Publisher API access. Never commit secrets.
 *
 * Inject [androidPublisher] in tests to avoid real API calls.
 */
import { GoogleAuth } from 'google-auth-library';

const ANDROID_PUBLISHER_SCOPE =
  'https://www.googleapis.com/auth/androidpublisher';

/**
 * purchaseState: 0 Purchased, 1 Canceled, 2 Pending
 * acknowledgementState: 0 Yet to be acknowledged, 1 Acknowledged
 */
export function createGooglePlayVerifier({
  androidPublisher,
  getAccessToken,
} = {}) {
  async function authHeaders() {
    if (getAccessToken) {
      const token = await getAccessToken();
      return { Authorization: `Bearer ${token}` };
    }
    const credentialsJson = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
    const auth = credentialsJson
      ? new GoogleAuth({
          credentials: JSON.parse(credentialsJson),
          scopes: [ANDROID_PUBLISHER_SCOPE],
        })
      : new GoogleAuth({ scopes: [ANDROID_PUBLISHER_SCOPE] });
    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const token =
      typeof tokenResponse === 'string'
        ? tokenResponse
        : tokenResponse?.token;
    if (!token) {
      throw new Error(
        'Unable to obtain Google Play API access token. '
          + 'Configure GOOGLE_PLAY_SERVICE_ACCOUNT_JSON or ADC.',
      );
    }
    return { Authorization: `Bearer ${token}` };
  }

  async function fetchJson(url, { method = 'GET', body } = {}) {
    if (androidPublisher) {
      if (typeof androidPublisher.request === 'function') {
        return androidPublisher.request({ url, method, body });
      }
      if (method === 'GET' && url.includes('/purchases/voidedpurchases')) {
        if (typeof androidPublisher.listVoidedPurchases === 'function') {
          return androidPublisher.listVoidedPurchases({ url });
        }
      }
      if (method === 'GET') {
        return androidPublisher.getPurchase({ url });
      }
      return androidPublisher.acknowledgePurchase({ url, body });
    }

    const headers = {
      ...(await authHeaders()),
      'Content-Type': 'application/json',
    };
    const response = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!response.ok) {
      const text = await response.text();
      const error = new Error(
        `Google Play API ${response.status}: ${text || response.statusText}`,
      );
      error.status = response.status;
      throw error;
    }
    if (response.status === 204) return {};
    const text = await response.text();
    return text ? JSON.parse(text) : {};
  }

  return {
    /**
     * GET purchases.products.get
     * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get
     */
    async getProductPurchase({ packageName, productId, purchaseToken }) {
      const url =
        'https://androidpublisher.googleapis.com/androidpublisher/v3'
        + `/applications/${encodeURIComponent(packageName)}`
        + `/purchases/products/${encodeURIComponent(productId)}`
        + `/tokens/${encodeURIComponent(purchaseToken)}`;
      return fetchJson(url, { method: 'GET' });
    },

    /**
     * POST purchases.products.acknowledge
     */
    async acknowledgeProductPurchase({
      packageName,
      productId,
      purchaseToken,
      developerPayload = '',
    }) {
      const url =
        'https://androidpublisher.googleapis.com/androidpublisher/v3'
        + `/applications/${encodeURIComponent(packageName)}`
        + `/purchases/products/${encodeURIComponent(productId)}`
        + `/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
      return fetchJson(url, {
        method: 'POST',
        body: { developerPayload },
      });
    },

    /**
     * GET purchases.voidedpurchases.list
     * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list
     *
     * type=0 → in-app (one-time) products only (default; matches V1 catalog).
     * Window cannot exceed the past 30 days per Google API limits.
     */
    async listVoidedPurchases({
      packageName,
      startTime = null,
      endTime = null,
      maxResults = 1000,
      token = null,
      type = 0,
      includeQuantityBasedPartialRefund = false,
    } = {}) {
      const params = new URLSearchParams();
      if (startTime != null) params.set('startTime', String(startTime));
      if (endTime != null) params.set('endTime', String(endTime));
      if (maxResults != null) params.set('maxResults', String(maxResults));
      if (token) params.set('token', String(token));
      if (type != null) params.set('type', String(type));
      if (includeQuantityBasedPartialRefund) {
        params.set('includeQuantityBasedPartialRefund', 'true');
      }
      const query = params.toString();
      const url =
        'https://androidpublisher.googleapis.com/androidpublisher/v3'
        + `/applications/${encodeURIComponent(packageName)}`
        + `/purchases/voidedpurchases${query ? `?${query}` : ''}`;
      return fetchJson(url, { method: 'GET' });
    },
  };
}

export function mapPurchaseState(purchaseState) {
  switch (Number(purchaseState)) {
    case 0:
      return 'PURCHASED';
    case 1:
      return 'CANCELED';
    case 2:
      return 'PENDING';
    default:
      return 'UNKNOWN';
  }
}
