#!/usr/bin/env python3
import os
import sys
import json
import argparse

# Add the current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

try:
    from semantic import extract_chapters as semantic_extract
    from dom_based import extract_chapters as dom_extract
    from pattern_based import extract_chapters as pattern_extract
    from toc_based import extract_chapters as toc_extract
except ImportError as e:
    print(json.dumps({
        'success': False,
        'error': f'Import error: {str(e)}. PYTHONPATH: {os.environ.get("PYTHONPATH")}, sys.path: {sys.path}'
    }), file=sys.stderr)
    sys.exit(1)

def main():
    try:
        parser = argparse.ArgumentParser(description='Extract chapters from ePub')
        parser.add_argument('--input', required=True, help='Input ePub file')
        parser.add_argument('--output', required=True, help='Output directory')
        parser.add_argument('--extractor', default='semantic', choices=['semantic', 'dom', 'pattern', 'toc'],
                          help='Extraction method to use')
        args = parser.parse_args()

        print(f'Starting extraction with args: {args}', file=sys.stderr)
        print(f'Current directory: {os.getcwd()}', file=sys.stderr)
        print(f'Script directory: {current_dir}', file=sys.stderr)
        print(f'PYTHONPATH: {os.environ.get("PYTHONPATH")}', file=sys.stderr)
        print(f'sys.path: {sys.path}', file=sys.stderr)

        # Create output directory if it doesn't exist
        os.makedirs(args.output, exist_ok=True)

        # Select extractor function
        extractors = {
            'semantic': semantic_extract,
            'dom': dom_extract,
            'pattern': pattern_extract,
            'toc': toc_extract
        }
        extract_func = extractors[args.extractor]

        # Extract chapters
        chapters = extract_func(args.input)
        
        # Write chapters to output directory
        for i, chapter in enumerate(chapters):
            chapter_file = os.path.join(args.output, f'chapter_{i+1}.txt')
            with open(chapter_file, 'w', encoding='utf-8') as f:
                f.write(chapter['content'])

        # Write metadata
        metadata = {
            'num_chapters': len(chapters),
            'chapters': [{'title': c.get('title', f'Chapter {i+1}')} for i, c in enumerate(chapters)]
        }
        with open(os.path.join(args.output, 'metadata.json'), 'w', encoding='utf-8') as f:
            json.dump(metadata, f, ensure_ascii=False, indent=2)

        print(json.dumps({
            'success': True,
            'message': f'Successfully extracted {len(chapters)} chapters'
        }))
        sys.exit(0)
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': str(e),
            'traceback': str(sys.exc_info())
        }), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
