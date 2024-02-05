import React, {useCallback, useEffect, useRef} from 'react';
import {
  findNodeHandle,
  requireNativeComponent,
  NativeModules,
  NativeEventEmitter,
} from 'react-native';
import {callNativeFunction} from '../utils/UIManagerHelpers';

const NativeComponent = requireNativeComponent('NativeMetaText');
const eventEmitter = new NativeEventEmitter(
  NativeModules.ReactNativeEventEmitter,
);

export const MetaTextView = React.forwardRef(
  (props: any, _ref: React.ForwardedRef<any>) => {
    const reactTag = useRef<number | null>();

    const onTextChange = useCallback(() => {
      callNativeFunction('onTextChange', 'NativeMetaText', reactTag.current);
    }, [reactTag]);

    useEffect(() => {
      eventEmitter.addListener('onMetaTextChange', onTextChange);
      setTimeout(() => {
        onTextChange();
      });

      return () => {
        eventEmitter.removeAllListeners;
      };
    }, [onTextChange]);

    return (
      <NativeComponent
        {...props}
        ref={nativeRef => (reactTag.current = findNodeHandle(nativeRef))}
      />
    );
  },
);
