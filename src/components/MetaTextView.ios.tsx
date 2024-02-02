import React, {useRef} from 'react';
import {findNodeHandle, requireNativeComponent} from 'react-native';
const NativeComponent = requireNativeComponent('NativeMetaText');

export const MetaTextView = React.forwardRef(
  (props: any, ref: React.ForwardedRef<any>) => {
    const reactTag = useRef<number | null>();

    return (
      <NativeComponent
        {...props}
        ref={nativeRef => (reactTag.current = findNodeHandle(nativeRef))}
      />
    );
  },
);
