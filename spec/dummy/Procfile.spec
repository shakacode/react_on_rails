client-static-assets: sh -c 'rm app/assets/javascripts/generated/* || true && cd client && npm run build:dev:client'
server-static-assets: sh -c 'cd client && npm run build:dev:server'
