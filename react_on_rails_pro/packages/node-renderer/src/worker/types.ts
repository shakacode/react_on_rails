import {
  FastifyInstance as LibFastifyInstance,
  FastifyRequest as LibFastifyRequest,
  FastifyReply as LibFastifyReply,
  RouteGenericInterface,
} from 'fastify';
import { Http2Server } from 'http2';

export type FastifyInstance = LibFastifyInstance<Http2Server>;

export type FastifyRequest = LibFastifyRequest<RouteGenericInterface, Http2Server>;

export type FastifyReply = LibFastifyReply<RouteGenericInterface, Http2Server>;
