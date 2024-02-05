import {UIManager} from 'react-native';

export const callNativeFunction = (
  functionName: string,
  nativeView: string,
  reactTag: number | null | undefined,
  props?: any[],
) => {
  if (!reactTag) {
    return;
  }
  UIManager.dispatchViewManagerCommand(
    reactTag,
    UIManager.getViewManagerConfig(nativeView).Commands[functionName],
    props,
  );
};
