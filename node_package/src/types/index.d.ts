import type { Component } from 'react';

export interface RegisteredComponent {
  name: string;
  component: Component;
  generatorFunction: boolean;
  isRenderer: boolean;
}

export interface RailsContext {
  railsEnv: "development" | "test" | "staging" | "production";
  inMailer: boolean;
  i18nLocale: string;
  i18nDefaultLocale: string;
  rorVersion: string;
  rorPro: boolean;
  serverSide: boolean
  originalUrl?: string;
  href?: string;
  location?: string;
  scheme?: string;
  host?: string;
  port?: string;
  pathname?: string;
  search?: string;
  httpAcceptLanguage?: string;
}

interface FileError extends Error {
  fileName: string;
  lineNumber: string;
}

export interface ErrorOptions {
  e: FileError;
  name?: string;
  jsCode?: string;
  serverSide: boolean;
}

export interface RenderParams {
  name?: string;
  componentObj: Component;
  props: Object;
  railsContext?: RailsContext;
  domNodeId?: string;
  trace?: string;
  shouldHydrate?: boolean;
}
