import { env } from 'shakapacker'
import { existsSync } from 'fs'
import { resolve } from 'path'

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`)
  if (existsSync(path)) {
    console.log(`Loading ENV specific rspack configuration file ${path}`)
    return require(path)
  }

  throw new Error(`Could not find file to load ${path}, based on NODE_ENV`)
}

export default envSpecificConfig()
