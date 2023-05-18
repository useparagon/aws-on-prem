import { ChildProcess, exec, spawn } from 'child_process';
import * as fs from 'fs';

import { WritableStream } from 'memory-streams';

export type ExecResult = {
  stdout: string;
  stderr: string;
};

/**
 * asynchronously executes a command to the terminal
 */
export function execAsync(
  command: string,
  env: NodeJS.ProcessEnv = {},
  pipeStdout: boolean = true,
): Promise<ExecResult> {
  return new Promise(
    (resolve: (value: ExecResult) => void, reject: (error: Error) => void): void => {
      const stdoutStream: WritableStream = new WritableStream({
        highWaterMark: 1024 * 1024 * 1024,
      });
      const stderrStream: WritableStream = new WritableStream({
        highWaterMark: 1024 * 1024 * 1024,
      });
      const childProcess: ChildProcess = exec(command, { env });

      childProcess.on('exit', (code: number) => {
        if (code !== 0) {
          return reject(new Error(stderrStream.toString().trim()));
        }

        return resolve({
          stdout: stdoutStream.toString(),
          stderr: stderrStream.toString(),
        });
      });

      childProcess.stdout?.pipe(stdoutStream);
      childProcess.stderr?.pipe(stderrStream);

      if (pipeStdout) {
        childProcess.stdout?.pipe(process.stdout);
        childProcess.stderr?.pipe(process.stderr);
      }
    },
  );
}

/**
 * spawns a child process and pipes terminal input into it
 */
export function spawnAsync(
  command: string,
  args: string[],
  env: NodeJS.ProcessEnv = {},
): Promise<ExecResult> {
  return new Promise((resolve: (value: ExecResult) => void, reject: (error: Error) => void) => {
    env = {
      ...process.env,
      ...env,
    };
    const childProcess: ChildProcess = spawn(command, args, {
      env,
    });
    const stdoutStream: WritableStream = new WritableStream({ highWaterMark: 1024 * 1024 * 1024 });
    const stderrStream: WritableStream = new WritableStream({ highWaterMark: 1024 * 1024 * 1024 });

    childProcess.stdout?.pipe(stdoutStream);
    childProcess.stderr?.pipe(stderrStream);
    childProcess.stdout?.pipe(process.stdout);
    childProcess.stderr?.pipe(process.stderr);

    // We need to pipe the parent process into the spawned process so user input is shared
    // However there's a bug with Node that creates a handle that doesn't get cleaned up when the child closes.
    // We need to call `unref()` on the child process as well as call `destroy()` on the parent stdin to get this to work correctly.
    // @ts-ignore: `childProcess.stdin` is possibly `null`
    process.stdin.pipe(childProcess.stdin);
    childProcess.unref();

    childProcess.on('exit', async (code: number) => {
      process.stdin.destroy();
      if (code !== 0) {
        return reject(new Error(`Failed command "${command} ${args.join(' ')}"`));
      }

      return resolve({
        stdout: stdoutStream.toString(),
        stderr: stderrStream.toString(),
      });
    });
  });
}

/**
 * loads the values in `.secure/.env-tf` into an object
 * @param filePath
 * @returns
 */
export async function getVariablesFromEnvFile(filePath: string): Promise<Record<string, string>> {
  const variables: Record<string, string> = {};
  const inputFile: string = await fs.promises.readFile(filePath, 'utf-8');
  inputFile
    .split('\n')
    .filter((line: string): boolean => !!line.trim().length)
    .filter((line: string): boolean => !line.startsWith('#'))
    .filter((line: string): boolean => {
      const parts: string[] = line.split('=');
      if (parts.length < 2) {
        // ignore lines without a key and value
        return false;
      } else if (!parts[1].trim().length) {
        // ignore empty values
        return false;
      }

      return true;
    })
    .map((line: string): void => {
      // incase a value has multiple `=`, this splits at the first instance of a `=`
      const [key, ...value] = line.split('=');
      const formattedKey: string = key.trim();
      const formattedValue: string = value.join('=').trim();
      variables[formattedKey] = formattedValue;
    });

  return variables;
}

let isDockerCached: boolean | undefined;

/**
 * determines if the process is running inside a docker container
 * used to map `host.docker.internal` -> `localhost`
 *
 * source code from https://github.com/sindresorhus/is-docker
 * added here because of ESM issues
 *
 * @returns boolean
 */
export function isDocker(): boolean {
  const hasDockerEnv = (): boolean | undefined => {
    try {
      fs.statSync('/.dockerenv');
      return true;
    } catch {
      return undefined;
    }
  };
  const hasDockerCGroup = (): boolean => {
    try {
      return fs.readFileSync('/proc/self/cgroup', 'utf8').includes('docker');
    } catch {
      return false;
    }
  };

  if (isDockerCached === undefined) {
    isDockerCached = hasDockerEnv() ?? hasDockerCGroup();
  }

  return isDockerCached;
}

/**
 * sleeps for n milliseconds
 * @param milliseconds
 * @returns
 */
export function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve: (value: any) => void) => setTimeout(resolve, milliseconds));
}
