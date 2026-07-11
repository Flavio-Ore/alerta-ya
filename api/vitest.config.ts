import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    env: {
      DEMO_MODE: 'false',
      KMS_PROJECT_ID: 'test-project',
      KMS_LOCATION_ID: 'global',
      KMS_KEY_RING_ID: 'panic-escrow',
      KMS_KEY_ID: 'panic-escrow-key',
      KMS_KEY_VERSION: '1',
    },
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
