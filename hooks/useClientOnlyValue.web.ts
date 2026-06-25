import React from 'react';

export function useClientOnlyValue<S, C>(server: S, client: C): S | C {
  const [value, setValue] = React.useState<S | C>(server);
  // Intentional: render the server value first, then switch to the client value
  // after hydration to avoid SSR/client markup mismatches. The post-mount setState
  // is the whole mechanism here, so the set-state-in-effect rule doesn't apply.
  React.useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setValue(client);
  }, [client]);

  return value;
}
