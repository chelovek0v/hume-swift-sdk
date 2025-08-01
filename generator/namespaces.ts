import * as OA from "./parse_openapi";
import type { Endpoint } from "./generator";

const exhaustive = (x: never): any => x;

export type Namespace = "tts" | "empathicVoice";

export const getNamespace = (path: string): Namespace => {
  if (path.startsWith("/v0/evi")) return "empathicVoice";
  if (path.startsWith("/v0/tts")) return "tts";
  throw new Error(`Unknown namespace for path: ${path}`);
};

export const calculateSchemaNamespaces = (
  allEndpoints: Array<Endpoint>,
  allChannels: OA.AsyncAPISpec["channels"],
  allMessages: OA.AsyncAPISpec["components"]["messages"],
): Map<string, Namespace> => {
  const ret: Map<string, Namespace> = new Map();
  const setNamespace = (schema: OA.JsonSchema, namespace: Namespace) => {
    if ("schemaKey" in schema && typeof schema.schemaKey === "string") {
      ret.set(schema.schemaKey, namespace);
    }
  };

  const channelNamespace = "empathicVoice";
  for (const channelPath in allChannels) {
    const channel = allChannels[channelPath];
    OA.walkAsyncAPIMessage(
      channel.publish.message,
      (m) => {
        if (m.kind === "message") {
          OA.walkSchema(m.payload, (s) => setNamespace(s, channelNamespace));
        }
      },
      allMessages,
    );
    OA.walkAsyncAPIMessage(
      channel.subscribe.message,
      (m) => {
        if (m.kind === "message") {
          OA.walkSchema(m.payload, (s) => setNamespace(s, channelNamespace));
        }
      },
      allMessages,
    );
  }

  OA.walkObject(allChannels, (obj) => {
    if (obj && typeof obj === "object" && "kind" in obj) {
      const { data, success } = OA.JsonSchema_.safeParse(obj);
      if (success) {
        setNamespace(data, channelNamespace);
      }
    }
  });

  for (const endpoint of allEndpoints) {
    if (endpoint.operation.kind === "ignored") {
      continue;
    }
    if (endpoint.operation.kind === "jsonBody") {
      OA.walkSchema(
        endpoint.operation.requestBody.content["application/json"].schema,
        (s) => setNamespace(s, endpoint.namespace),
      );
    }
    endpoint.operation.parameters.forEach(({ schema }) => {
      OA.walkSchema(schema, (s) => setNamespace(s, endpoint.namespace));
    });
    Object.values(endpoint.operation.responses ?? []).forEach((response) => {
      switch (response.kind) {
        case "jsonResponse":
          OA.walkSchema(response.content["application/json"].schema, (s) =>
            setNamespace(s, endpoint.namespace),
          );
          return;
        case "binaryResponse":
          OA.walkSchema(response.content["audio/*"].schema, (s) =>
            setNamespace(s, endpoint.namespace),
          );
          return;
        case "noContent":
          return;
        default:
          return exhaustive(response);
      }
    });
  }
  return ret;
}; 
