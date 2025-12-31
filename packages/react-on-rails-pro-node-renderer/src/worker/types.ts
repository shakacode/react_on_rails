import {
  FastifyInstance as LibFastifyInstance,
  FastifyReply as LibFastifyReply,
  RouteGenericInterface,
} from 'fastify';
import { Http2Server } from 'http2';

export type FastifyInstance = LibFastifyInstance<Http2Server>;

export type FastifyReply = LibFastifyReply<RouteGenericInterface, Http2Server>;
