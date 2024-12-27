from abc import ABC, abstractmethod

class ChapterExtractor(ABC):
    """Classe de base abstraite pour les extracteurs de chapitres."""
    
    @abstractmethod
    def extract_chapters(self, epub_file, content):
        """
        Extrait les chapitres du contenu fourni.
        
        Args:
            epub_file: Le fichier EPUB d'origine
            content: Le contenu HTML du fichier
            
        Returns:
            list: Liste de dictionnaires contenant les informations des chapitres
        """
        pass
