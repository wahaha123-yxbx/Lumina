import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'Lumina-EntryAbility'

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'Lumina App onCreate')
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'Lumina App onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'Lumina App onWindowStageCreate')

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, `Failed to load the content. Cause: ${JSON.stringify(err)}`)
        return
      }
      hilog.info(0x0000, TAG, 'Succeeded in loading the content.')
    })

    windowStage.getMainWindow().then((mainWindow) => {
      // 设置沉浸式状态栏
      mainWindow.setWindowSystemBarProperties({
        navigationBarColor: '#0F0F23',
        statusBarColor: '#0F0F23',
        navigationBarContentColor: '#E8E8F0',
        statusBarContentColor: '#E8E8F0',
      })
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'Lumina App onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'Lumina App onForeground')
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'Lumina App onBackground')
  }
}
