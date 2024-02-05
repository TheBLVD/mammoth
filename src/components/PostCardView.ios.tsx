import React, {useCallback, useEffect, useRef} from 'react';
import {findNodeHandle, requireNativeComponent} from 'react-native';
import {callNativeViewMethod} from '../utils/UIManagerHelpers';
const NativeComponent = requireNativeComponent('NativePostCardView');

export const PostCardView = React.forwardRef(
  (props: any, ref: React.ForwardedRef<any>) => {
    const reactTag = useRef<number | null>();

    const configure = useCallback(
      (text: string) => {
        callNativeViewMethod(
          'configure',
          'NativePostCardView',
          reactTag.current,
          [text],
        );
      },
      [reactTag],
    );

    useEffect(() => {
      (ref as any).current = {configure};
    }, [configure, ref]);

    return (
      <NativeComponent
        {...props}
        ref={nativeRef => (reactTag.current = findNodeHandle(nativeRef))}
      />
    );
  },
);
