import * as OA from "./parse_openapi";
import type { JsonSchema } from "./parse_openapi";
import { camelCase, pascalCase } from "change-case";
import type { Endpoint } from "./directions";
import type { SwiftType, SwiftDefinition, SDKMethod } from "./swift";
import type { SwiftSDK } from "./generator";
import type { Namespace } from "./generator";

type UnIgnored<T> = T extends { kind: "ignored" } ? never : T;



// kebab-case to PascalCase
export const normalizeResourceName = (resourceName: string) => {
  return pascalCase(resourceName.replace(/-/g, " "));
};

// gets rid of some square brackets that appear in the tts api
export const normalizeObjectName = (title: string) => {
  return pascalCase(title.replace(/\[.*\]/, ""));
};

export const normalizedEnumNameFromValue = (enumValue: string, enumName: string) => {
  // Replace /, *, ., or - with underscores
  // trim leading or trailing underscores
  // convert to camel case
  // If the enum value begins with a number, prefix it with an underscore
  let name = enumValue;
  name = name.replace(/\/|\*|-|\(|\)/g, "_");
  name = name.replace(/\./g, "_");
  name = name.replace(/^_+|_+$/g, "");
  if (name.match(/^[0-9]/)) {
    name = "_" + name;
  }
  name = camelCase(name);

  if (/^([0-9]+)/.test(name)) {
    name = `${pascalCase(enumName)}_` + name;
  }
  return name;
};

export const getMethodName = (operation: UnIgnored<OA.OpenAPIOperation>): string => {
  if (operation["x-fern-sdk-method-name"]) {
    return camelCase(operation["x-fern-sdk-method-name"]);
  }

  // Fallback to operationId if available
  if (operation.operationId) {
    return camelCase(operation.operationId);
  }

  // If no operationId, throw an exception - missing operationId is a serious issue
  throw new Error("Missing operationId in OpenAPI operation");
};



export const swiftName = (schema: JsonSchema, surroundingName?: string): string => {
  if (schema.kind === "ignored") {
    return "TODO_IGNORED_TYPE";
  }

  if (schema.kind === "enum") {
    const result =
      schema["x-fern-type-name"] ??
      schema.title ??
      schema.schemaKey ??
      surroundingName;
    if (!result) {
      // For the specific HUME_AI, CUSTOM_VOICE enum, use a TODO name to help identify it
      if (
        schema.enum &&
        schema.enum.length === 2 &&
        schema.enum.includes("HUME_AI") &&
        schema.enum.includes("CUSTOM_VOICE")
      ) {
        return "TODO_VOICE_PROVIDER";
      }

      // Return a TODO name to help identify where this is used
      return "TODO_UNNAMED_ENUM";
    }
    return result;
  }
  if (schema.kind === "object") {
    const result =
      schema["x-fern-type-name"] ??
      schema.title ??
      schema.schemaKey ??
      "TODO_OBJECT_HAD_NO_NAME";
    return normalizeObjectName(result);
  }
  if (schema.kind === "discriminatedUnion") {
    return schema.title ? schema.title : "TODO_DISCRIMINATED_UNION_HAD_NO_NAME";
  }

  if (schema.kind === "dictionary") {
    let result = "Dictionary";
    if (
      "x-fern-type-name" in schema &&
      schema["x-fern-type-name"] &&
      typeof schema["x-fern-type-name"] === "string"
    ) {
      result = schema["x-fern-type-name"];
    } else if (
      "title" in schema &&
      schema.title &&
      typeof schema.title === "string"
    ) {
      result = schema.title;
    } else if (
      "schemaKey" in schema &&
      schema.schemaKey &&
      typeof schema.schemaKey === "string"
    ) {
      result = schema.schemaKey;
    }
    return normalizeObjectName(result);
  }

  if (schema.kind === "anyOfRefs") {
    return normalizeObjectName(
      schema.schemaKey ?? surroundingName ?? "TODO_ANY_OF_REFS_HAD_NO_NAME",
    );
  }

  throw new Error(
    `Attempted to produce name for unnameable schema kind: ${schema.kind}`,
  );
};

export const getResourceName = ({ operation, path }: Endpoint) => {
  if (operation.kind === "ignored") {
    throw new Error();
  }
  if (operation["x-fern-sdk-group-name"])
    // x-fern-sdk-group name is the name of the property that defines the "resource" that the operation belongs to
    return normalizeResourceName(operation["x-fern-sdk-group-name"]);
  if (path.startsWith("/v0/tts")) return "TTS";
  throw new Error(`Unable to determine SDK group of operation ${path}`);
};

// Define a list of type names that need to be renamed due to collisions
// Each entry maps from original name to a Record of namespace to renamed name
const typeRenames: Record<string, Record<string, string>> = {
  Encoding: {
    tts: "AudioEncoding",
  },
  VoiceProvider: {
    tts: "TTSVoiceProvider",
  },
  Voice: {
    tts: "Voice",
  },
};

// Apply renames to a definition name based on the namespace
export const applyRename = (definitionName: string, namespace: Namespace): string => {
  const namespaceStr = namespace === "empathicVoice" ? "empathicVoice" : "tts";
  if (definitionName in typeRenames) {
    // If this definition name is in our rename list and there's a specific rename for this namespace
    if (namespaceStr in typeRenames[definitionName]) {
      return typeRenames[definitionName][namespaceStr];
    }
  }
  return definitionName;
};

// Update references within a SwiftType to use renamed types
export const updateTypeReferences = (
  type: SwiftType,
  namespace: Namespace,
): SwiftType => {
  switch (type.type) {
    case "Reference":
      return {
        type: "Reference",
        name: applyRename(type.name, namespace),
      };
    case "Optional":
      return {
        type: "Optional",
        wrapped: updateTypeReferences(type.wrapped, namespace),
      };
    case "Array":
      return {
        type: "Array",
        element: updateTypeReferences(type.element, namespace),
      };
    case "Dictionary":
      return {
        type: "Dictionary",
        key: type.key,
        value: updateTypeReferences(type.value, namespace),
      };
    default:
      return type;
  }
};

export const resolveNamingCollisions = (sdk: SwiftSDK): SwiftSDK => {
  // First, detect all collisions
  const nameToNamespaces: Record<string, string[]> = {};

  for (const namespaceName in sdk.namespaces) {
    const namespace = sdk.namespaces[namespaceName];
    for (const definition of namespace.definitions) {
      if (!nameToNamespaces[definition.name]) {
        nameToNamespaces[definition.name] = [];
      }
      nameToNamespaces[definition.name].push(namespaceName);
    }
  }

  const newSdk: SwiftSDK = {
    namespaces: {},
  };

  for (const namespaceName in sdk.namespaces) {
    newSdk.namespaces[namespaceName] = {
      resourceClients: [],
      definitions: [],
    };
  }

  for (const namespaceName in sdk.namespaces) {
    const namespace = sdk.namespaces[namespaceName];
    const namespaceEnum = namespaceName === "empathicVoice" ? "empathicVoice" : "tts";

    for (const definition of namespace.definitions) {
      let newDef: SwiftDefinition;
      const newName = applyRename(definition.name, namespaceEnum);

      if (definition.type === "enum") {
        newDef = {
          ...definition,
          name: newName,
        };
      } else if (definition.type === "struct") {
        // Update property types to use renamed references
        const newProperties = definition.properties.map((prop) => ({
          ...prop,
          type: updateTypeReferences(prop.type, namespaceEnum),
        }));

        newDef = {
          ...definition,
          name: newName,
          properties: newProperties,
        };
      } else if (definition.type === "discriminatedUnion") {
        // Update case types to use renamed references
        const newCases = definition.cases.map((c) => ({
          ...c,
          type: updateTypeReferences(c.type, namespaceEnum),
        }));

        newDef = {
          ...definition,
          name: newName,
          cases: newCases,
        };
      } else {
        newDef = definition; // Shouldn't happen due to exhaustive typing
      }

      newSdk.namespaces[namespaceName].definitions.push(newDef);
    }

    // Handle resource clients - update references in methods
    for (const resourceClient of namespace.resourceClients) {
      const updatedMethods = resourceClient.methods.map((method) => {
        // Update parameter types
                  const newParams = method.parameters.map((param) => ({
            ...param,
            type: updateTypeReferences(param.type, namespaceEnum),
          }));

          // Update return type
          const newReturnType = updateTypeReferences(
            method.returnType,
            namespaceEnum,
          );

        return {
          ...method,
          parameters: newParams,
          returnType: newReturnType,
        };
      });

      newSdk.namespaces[namespaceName].resourceClients.push({
        name: resourceClient.name,
        methods: updatedMethods,
      });
    }
  }

  return newSdk;
};

export const detectNamingCollisions = (sdk: SwiftSDK) => {
  const allNames = new Set<string>();
  for (const namespaceName in sdk.namespaces) {
    const namespace = sdk.namespaces[namespaceName];
    for (const definition of namespace.definitions) {
      if (allNames.has(definition.name)) {
        // Naming collision detected
      }
      allNames.add(definition.name);
    }
  }
}; 