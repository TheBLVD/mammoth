import React, {useCallback, useEffect, useRef} from 'react';
import {UIManager, findNodeHandle, requireNativeComponent} from 'react-native';
const NativeComponent = requireNativeComponent('NativePostCardView');

export const PostCardView = React.forwardRef(
  (props: any, ref: React.ForwardedRef<any>) => {
    const reactTag = useRef<number | null>();

    const configure = useCallback(
      (text: string) => {
        UIManager.dispatchViewManagerCommand(
          reactTag.current as number | null,
          UIManager.getViewManagerConfig('NativePostCardView').Commands
            .configure,
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
