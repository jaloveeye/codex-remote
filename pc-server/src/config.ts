/**
 * Legacy placeholder configuration for the deprecated PC bridge.
 */

export const CONFIG = {
  RELAY_SERVER_URL: process.env.RELAY_SERVER_URL || 'https://relay.example.com',
} as const;
