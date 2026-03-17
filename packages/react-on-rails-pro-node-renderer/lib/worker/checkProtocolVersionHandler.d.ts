export interface RequestBody {
    protocolVersion?: string;
    gemVersion?: string;
    railsEnv?: string;
}
export declare function checkProtocolVersion(body: RequestBody): {
    headers: {
        'Cache-Control': string;
    };
    status: number;
    data: string;
} | undefined;
//# sourceMappingURL=checkProtocolVersionHandler.d.ts.map