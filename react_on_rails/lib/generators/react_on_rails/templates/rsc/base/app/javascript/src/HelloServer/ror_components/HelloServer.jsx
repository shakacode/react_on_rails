// HelloServer Entry Point - Re-exports the server component for auto_load_bundle
// This file is discovered by React on Rails' auto_load_bundle feature
// and registered automatically in both client and server bundles.
//
// Note: No 'use client' directive here - this is a Server Component.
// The actual component in ../components/HelloServer.jsx runs only on the server.

import HelloServer from '../components/HelloServer';

export default HelloServer;
