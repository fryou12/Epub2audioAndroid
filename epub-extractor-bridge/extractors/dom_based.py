from bs4 import BeautifulSoup
import re
from . import ChapterExtractor

class DOMBasedExtractor(ChapterExtractor):
    """Extracteur de chapitres basé sur la structure DOM du document."""
    
    def __init__(self):
        self.chapter_indicators = [
            'chapter',
            'chapitre',
            'partie',
            'part',
            'section'
        ]
    
    def extract_chapters(self, epub_file, content):
        chapters = []
        found_chapters = set()
        soup = BeautifulSoup(content, 'html.parser')
        
        # Rechercher les balises qui pourraient contenir des chapitres
        potential_chapters = []
        for indicator in self.chapter_indicators:
            # Chercher dans les classes
            potential_chapters.extend(soup.find_all(class_=re.compile(indicator, re.I)))
            # Chercher dans les IDs
            potential_chapters.extend(soup.find_all(id=re.compile(indicator, re.I)))
            # Chercher dans les balises h1-h6 contenant le mot
            for h in range(1, 7):
                potential_chapters.extend(
                    soup.find_all(f'h{h}', string=re.compile(indicator, re.I))
                )
        
        for element in potential_chapters:
            chapter_info = self._extract_chapter_info(element)
            if chapter_info and chapter_info['number'] not in found_chapters:
                chapters.append(chapter_info)
                found_chapters.add(chapter_info['number'])
        
        return sorted(chapters, key=lambda x: x['number'])
    
    def _extract_chapter_info(self, element):
        """Extrait les informations du chapitre à partir d'un élément DOM."""
        text = element.get_text().strip()
        
        # Rechercher le numéro de chapitre
        number_match = re.search(r'\d+', text)
        if not number_match:
            return None
            
        chapter_number = int(number_match.group())
        if not (1 <= chapter_number <= 100):  # Limite raisonnable
            return None
            
        # Obtenir le titre (texte après le numéro)
        title = text[number_match.end():].strip(' -:')
        if not title:
            title = f"Chapitre {chapter_number}"
            
        # Obtenir le contenu (tous les éléments suivants jusqu'au prochain chapitre)
        content_elements = []
        next_element = element.find_next_sibling()
        while next_element:
            if self._is_chapter_header(next_element):
                break
            if next_element.name not in ['script', 'style']:
                content_elements.append(next_element.get_text().strip())
            next_element = next_element.find_next_sibling()
            
        content = '\n'.join(content_elements)
        if len(content) < 100:  # Ignorer les chapitres trop courts
            return None
            
        return {
            'number': chapter_number,
            'title': f'Chapitre {chapter_number} - {title}',
            'content': content
        }
    
    def _is_chapter_header(self, element):
        """Vérifie si l'élément est un en-tête de chapitre."""
        if not element:
            return False
            
        text = element.get_text().lower()
        return any(indicator in text for indicator in self.chapter_indicators)
