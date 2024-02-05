import {useEffect} from 'react';
import {NativeModules} from 'react-native';
import {registerCustomButtons} from '../../_navigation/registerCustomButtons';
import {LeftButton} from './components/LeftButton';
import {RightButton} from './components/RightButton';

const nativeNavigator = NativeModules.Navigator;

export const useScreenRegister = (screenId: number) => {
  useEffect(() => {
    const left = registerCustomButtons([
      {
        id: 'mammoth.nav.cancel',
        title: 'Cancel',
        component: () => LeftButton({screenId: screenId}),
        disabled: false,
      },
    ]);

    const right = registerCustomButtons([
      {
        id: 'mammoth.nav.post',
        title: 'Post',
        component: () => RightButton({screenId: screenId}),
        disabled: true,
      },
    ]);

    nativeNavigator.registerRootView(screenId, {
      leftButtons: left,
      rightButtons: right,
    });
    nativeNavigator.onRootViewEnteredHierarchy(() => {
      nativeNavigator.registerRootView(screenId, {
        leftButtons: left,
        rightButtons: right,
      });
    });

    return () => nativeNavigator.unregisterRootView(screenId);
  }, [screenId]);
};
