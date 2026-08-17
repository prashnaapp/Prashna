/**
 * Pub/Sub trigger for Google Play Real-time Developer Notifications.
 *
 * Topic (default): play-rtdn
 * Region: asia-south1 (global Functions options)
 *
 * Do not deploy until Play Console RTDN + Pub/Sub topic are configured.
 */
import { onMessagePublished } from 'firebase-functions/v2/pubsub';

import { getDb } from './firebase.js';
import { createRtdnService } from './rtdn_service.js';

export const PLAY_RTDN_TOPIC =
  process.env.PLAY_RTDN_TOPIC || 'play-rtdn';

export const onPlayRtdn = onMessagePublished(
  {
    topic: PLAY_RTDN_TOPIC,
    region: 'asia-south1',
    retry: true,
  },
  async (event) => {
    const service = createRtdnService({ db: getDb() });
    const result = await service.processCloudEvent(event);

    // Permanent rejects / skips complete successfully so Pub/Sub does not retry.
    // Retryable Google API failures throw from processEnvelope and nack the message.
    if (result?.inProgress) {
      // Another worker is processing; signal retry.
      throw new Error(
        `RTDN message ${result.messageId} is already processing; retry later.`,
      );
    }

    return result;
  },
);
