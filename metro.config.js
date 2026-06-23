const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");

const config = getDefaultConfig(__dirname);

config.resolver = {
    ...config.resolver,
    extraNodeModules: {
        ...config.resolver?.extraNodeModules,
        buffer: require.resolve('buffer/'),
    },
};

const originalGetPolyfills = config.serializer?.getPolyfills?.bind(config.serializer);
config.serializer = {
    ...config.serializer,
    getPolyfills: ({ platform }) => {
        const base = originalGetPolyfills ? originalGetPolyfills({ platform }) : [];
        return [
            require.resolve('./polyfills/EventPatch.js'), // must run before base to intercept defineProperty
            require.resolve('./polyfills/DOMException.js'),
            ...base,
        ];
    },
};

module.exports = withNativeWind(config, { input: "./global.css" });
