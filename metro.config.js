const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");

const config = getDefaultConfig(__dirname);
// ── SVG via react-native-svg-transformer ─────────────────────
config.transformer = {
    ...config.transformer,
    babelTransformerPath: require.resolve("react-native-svg-transformer"),
}
// ── Fix: @supabase/realtime-js Metro ESM resolution bug ─────────────────────
// Metro can't resolve "./RealtimeClient" from realtime-js because the package
// ships both CJS and ESM but Metro picks up the wrong entry. We force it to
// the CJS main dist folder so all internal requires resolve correctly.
config.resolver = {
    ...config.resolver,
    extraNodeModules: {
        ...config.resolver?.extraNodeModules,
        buffer: require.resolve('buffer/'),
    },
    assetExts: config.resolver.assetExts.filter(ext => ext !== 'svg'),
    sourceExts: [...config.resolver.sourceExts, 'svg'],
    resolveRequest: (context, moduleName, platform) => {
        // Intercept the broken relative require inside realtime-js
        if (
            moduleName === './RealtimeClient' &&
            context.originModulePath.includes('@supabase/realtime-js')
        ) {
            return {
                filePath: path.resolve(
                    __dirname,
                    'node_modules/@supabase/realtime-js/dist/main/RealtimeClient.js'
                ),
                type: 'sourceFile',
            };
        }
        // Fall through to default resolver for everything else
        return context.resolveRequest(context, moduleName, platform);
    },
};

// Allow Metro to understand .cjs files (used by some Supabase sub-packages)
config.resolver.sourceExts = [
    ...config.resolver.sourceExts,
    'cjs',
];

const originalGetPolyfills = config.serializer?.getPolyfills?.bind(config.serializer);
config.serializer = {
    ...config.serializer,
    getPolyfills: ({ platform }) => {
        const base = originalGetPolyfills ? originalGetPolyfills({ platform }) : [];
        return [
            require.resolve('./polyfills/DOMException.js'),
            ...base,
        ];
    },
};

module.exports = withNativeWind(config, { input: "./global.css" });
