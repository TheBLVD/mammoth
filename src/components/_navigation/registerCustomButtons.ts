import {AppRegistry} from 'react-native';

type NavigatorButton = {
  id: string;
  title?: string;
  component?: React.ComponentType<any>;
  image?: any;
  disabled?: boolean;
};

export const registerCustomButtons = (buttons: NavigatorButton[]) => {
  if (!buttons) {
    return;
  }
  // Iterate through currentRoute's navigator buttons to register any custom nav button components
  return buttons.map(button => {
    if (button.component) {
      AppRegistry.registerComponent(button.id, () => button.component!);
      return {
        ...button,
        // Replace the component with an id so native can use it to fetch the RN view
        component: button.id,
      };
    }
    // Handle images
    if (button.image) {
      const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
      const resolvedImage = resolveAssetSource(button.image);
      return {
        ...button,
        image: resolvedImage,
      };
    }
    return button;
  });
};
