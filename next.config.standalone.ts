import type { NextConfig } from "next";

/**
 * Reference next.config.ts for self-hosted / containerized deployments.
 *
 * The only addition over the upstream Firesearch config is `output: 'standalone'`,
 * which emits a self-contained `.next/standalone` directory (with a `server.js`
 * entrypoint and a pruned node_modules) that the Dockerfile copies into the
 * runtime image.
 *
 * To use: replace the repository's `next.config.ts` with this file, or add the
 * `output: 'standalone'` line to the existing config.
 */
const nextConfig: NextConfig = {
  output: "standalone",
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "www.google.com",
        pathname: "/s2/favicons**",
      },
    ],
  },
};

export default nextConfig;
