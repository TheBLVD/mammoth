import {AppRegistry, LogBox} from 'react-native';
import {Composer} from './src/components/_screens/Composer';

LogBox.ignoreAllLogs();

AppRegistry.registerComponent('Composer', () => Composer);
