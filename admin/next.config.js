/** @type {import('next').NextConfig} */
const path = require('path')
const nextConfig = {
  reactStrictMode: true,
  swcMinify: false,
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
  images: {
    domains: ['firebasestorage.googleapis.com'],
  },
  // Чтобы Next не путался из-за lockfile'ов выше по дереву (Windows workspace).
  outputFileTracingRoot: __dirname,
  webpack: (config) => {
    config.resolve = config.resolve || {}
    config.resolve.alias = config.resolve.alias || {}
    config.resolve.alias['@'] = path.join(__dirname, 'src')
    // Firebase pulls undici (>= 6) which uses ES2022 private class fields.
    // Next 14 + webpack 5 cannot parse it. Node 18+ has a native fetch, so
    // we short-circuit any "undici" import to an empty module.
    config.resolve.alias['undici'] = false
    return config
  },
}

module.exports = nextConfig
