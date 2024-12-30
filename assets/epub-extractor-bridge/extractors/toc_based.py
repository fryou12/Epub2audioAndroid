from bs4 import BeautifulSoup
import re
from . import ChapterExtractor

class TOCBasedExtractor(ChapterExtractor):
    """Extracteur de chapitres basé sur la table des matières de l'EPUB."""
    
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
        
        # Trouver le fichier OPF
        opf_content = self._find_opf_content(epub_file)
        if not opf_content:
            return []
            
        # Parser le fichier OPF pour trouver la table des matières
        opf_soup = BeautifulSoup(opf_content, 'xml')
        toc_href = self._find_toc_href(opf_soup)
        if not toc_href:
            return []
            
        # Lire le contenu de la table des matières
        try:
            toc_content = epub_file.read(toc_href).decode('utf-8')
            toc_soup = BeautifulSoup(toc_content, 'xml')
            
            # Extraire les points de navigation
            nav_points = toc_soup.find_all(['navPoint', 'navLabel'])
            for i, nav in enumerate(nav_points, 1):
                chapter_info = self._extract_chapter_info(nav, i)
                if chapter_info and chapter_info['number'] not in found_chapters:
                    chapters.append(chapter_info)
                    found_chapters.add(chapter_info['number'])
                    
        except Exception as e:
            print(f"Erreur lors de la lecture de la table des matières: {str(e)}")
            return []
            
        return sorted(chapters, key=lambda x: x['number'])
    
    def _find_opf_content(self, epub_file):
        """Trouve et lit le contenu du fichier OPF."""
        try:
            # Chercher le fichier container.xml
            container = epub_file.read('META-INF/container.xml').decode('utf-8')
            container_soup = BeautifulSoup(container, 'xml')
            
            # Trouver le chemin vers le fichier OPF
            rootfile = container_soup.find('rootfile')
            if rootfile and 'full-path' in rootfile.attrs:
                opf_path = rootfile['full-path']
                return epub_file.read(opf_path).decode('utf-8')
        except Exception as e:
            print(f"Erreur lors de la recherche du fichier OPF: {str(e)}")
        return None
    
    def _find_toc_href(self, opf_soup):
        """Trouve le chemin vers la table des matières dans le fichier OPF."""
        # Chercher dans les métadonnées
        spine = opf_soup.find('spine')
        if spine and 'toc' in spine.attrs:
            toc_id = spine['toc']
            manifest = opf_soup.find('manifest')
            if manifest:
                toc_item = manifest.find(id=toc_id)
                if toc_item and 'href' in toc_item.attrs:
                    return toc_item['href']
        return None
    
    def _extract_chapter_info(self, nav_point, index):
        """Extrait les informations du chapitre à partir d'un point de navigation."""
        try:
            label = nav_point.find('text')
            if not label:
                return None
                
            text = label.get_text().strip()
            
            # Rechercher le numéro de chapitre
            number_match = re.search(r'\d+', text)
            chapter_number = int(number_match.group()) if number_match else index
            
            # Vérifier si c'est bien un chapitre
            lower_text = text.lower()
            if not any(indicator in lower_text for indicator in self.chapter_indicators):
                return None
                
            # Obtenir le titre
            title = text
            if number_match:
                title = text[number_match.end():].strip(' -:')
            if not title:
                title = f"Chapitre {chapter_number}"
                
            # Obtenir le contenu
            content_src = nav_point.find('content')
            if content_src and 'src' in content_src.attrs:
                return {
                    'number': chapter_number,
                    'title': f'Chapitre {chapter_number} - {title}',
                    'content': content_src['src']  # Référence au contenu
                }
                
        except Exception as e:
            print(f"Erreur lors de l'extraction des informations du chapitre: {str(e)}")
            
        return None
