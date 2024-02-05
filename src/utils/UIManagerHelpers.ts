import {UIManager} from 'react-native';

export const callNativeViewMethod = (
  methodName: string,
  nativeView: string,
  reactTag: number | null | undefined,
  props?: any[],
) => {
  if (!reactTag) {
    return;
  }
  UIManager.dispatchViewManagerCommand(
    reactTag,
    UIManager.getViewManagerConfig(nativeView).Commands[methodName],
    props,
  );
};
