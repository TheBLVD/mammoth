import React from 'react';
import {Button, NativeModules} from 'react-native';
const nativeNavigator = NativeModules.Navigator;

type Props = {
  screenId: number;
};

export const LeftButton = ({screenId}: Props) => {
  return (
    <Button
      onPress={() => nativeNavigator.dismissFromReactTag(screenId)}
      title="Cancel"
      color="#fff"
    />
  );
};
