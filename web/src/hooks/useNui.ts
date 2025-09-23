import { useCallback } from 'react';
import { NuiMessage, NuiCallbackData } from '../types';

declare global {
  interface Window {
    invokeNative?: (native: string, ...args: any[]) => void;
  }
}

declare function GetParentResourceName(): string;

export const useNui = () => {
  const sendNuiCallback = useCallback((eventName: string, data: NuiCallbackData, cb?: (data: any) => void) => {
    fetch(`https://${GetParentResourceName()}/${eventName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data)
    })
    .then(resp => resp.json())
    .then(resp => cb && cb(resp))
    .catch(error => {
      console.error('NUI callback error:', error);
      cb && cb({ error: 'Callback failed' });
    });
  }, []);

  const closeNui = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/vendor:close`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify({})
    });
  }, []);

  const listenForNuiMessages = useCallback((callback: (message: NuiMessage) => void) => {
    const handleMessage = (event: MessageEvent) => {
      try {
        let data = event.data;
        if (typeof data === 'string') {
          data = JSON.parse(data);
        }
        callback(data);
      } catch (error) {
        console.error('Failed to parse NUI message:', error);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return {
    sendNuiCallback,
    closeNui,
    listenForNuiMessages
  };
};
