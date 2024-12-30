import re
import html2text
from . import ChapterExtractor

class PatternBasedExtractor(ChapterExtractor):
    """Extracteur de chapitres basé sur les motifs de texte."""
    
    def __init__(self):
        self.h = html2text.HTML2Text()
        self.h.ignore_links = True
        self.h.ignore_images = True
        self.h.ignore_tables = True
        self.patterns = [
            r'^\s*#\s*(\d+)\s*$',                    # Format "# X"
            r'^\s*Chapitre\s+(\d+)\s*$',             # Format "Chapitre X"
            r'^\s*CHAPITRE\s+(\d+)\s*$',             # Format "CHAPITRE X"
            r'^\s*Chapter\s+(\d+)\s*$',              # Format "Chapter X"
            r'^\s*(\d+)\s*$'                         # Format "X" (juste le numéro)
        ]
    
    def extract_chapters(self, epub_file, content):
        chapters = []
        found_chapters = set()
        
        # Convertir le HTML en texte
        text_content = self.h.handle(content)
        lines = [line.rstrip() for line in text_content.split('\n')]
        
        i = 0
        while i < len(lines):
            chapter_number, title, content = self._get_chapter_content(lines[i:])
            if chapter_number is not None and title and content:
                if chapter_number not in found_chapters:
                    if len(content) >= 100:
                        chapters.append({
                            'number': chapter_number,
                            'title': f'Chapitre {chapter_number} - {title}',
                            'content': content
                        })
                        found_chapters.add(chapter_number)
            i += 1
        
        return chapters
    
    def _get_chapter_content(self, content_lines):
        """Extrait le titre et le numéro du chapitre des premières lignes du contenu."""
        for i, line in enumerate(content_lines):
            line = line.strip()
            if not line:
                continue
                
            for pattern in self.patterns:
                match = re.match(pattern, line, re.IGNORECASE)
                if match:
                    chapter_number = int(match.group(1))
                    if 1 <= chapter_number <= 100:  # Limite raisonnable pour le nombre de chapitres
                        title = None
                        content = None
                        
                        # Chercher le titre dans les lignes suivantes
                        title_index = i + 1
                        while title_index < len(content_lines):
                            potential_title = content_lines[title_index].strip()
                            if potential_title:
                                title = potential_title
                                content = '\n'.join(content_lines[title_index + 1:]).strip()
                                return chapter_number, title, content
                            title_index += 1
        
        return None, None, None
