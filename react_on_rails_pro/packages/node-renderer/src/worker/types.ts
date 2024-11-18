import {
  FastifyRequest as LibFastifyRequest,
  FastifyReply as LibFastifyReply,
  RouteGenericInterface,
} from 'fastify';
import { Http2Server } from 'http2';

export type FastifyRequest = LibFastifyRequest<RouteGenericInterface, Http2Server>;

export type FastifyReply = LibFastifyReply<Http2Server>;
