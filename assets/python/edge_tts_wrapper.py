#!/usr/bin/env python3
import asyncio
import edge_tts
import json
import sys

async def get_voices():
    try:
        voices = await edge_tts.list_voices()
        print(json.dumps([{
            'name': voice['Name'],
            'locale': voice['Locale'],
            'gender': voice['Gender'],
            'shortName': voice['ShortName']
        } for voice in voices]))
    except Exception as e:
        print(f"Error getting voices: {str(e)}", file=sys.stderr)
        sys.exit(1)

async def speak_text(text, voice, output_file):
    try:
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(output_file)
        print(json.dumps({'success': True, 'file': output_file}))
    except Exception as e:
        print(f"Error speaking text: {str(e)}", file=sys.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Error: No command specified", file=sys.stderr)
        sys.exit(1)
        
    command = sys.argv[1]
    
    if command == "get_voices":
        asyncio.run(get_voices())
    elif command == "speak":
        if len(sys.argv) < 5:
            print("Error: Missing arguments for speak command", file=sys.stderr)
            sys.exit(1)
        text = sys.argv[2]
        voice = sys.argv[3]
        output_file = sys.argv[4]
        asyncio.run(speak_text(text, voice, output_file))
    else:
        print(f"Error: Unknown command {command}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
