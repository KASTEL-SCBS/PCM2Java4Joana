package edu.kit.kastel.scbs.pcm2java4joana.generator

import edu.kit.ipd.sdq.mdsd.pcm2java.generator.PCM2JavaGenerator
import java.util.List
import org.eclipse.internal.xtend.util.Triplet


class PCM2Java4JOANAGenerator extends PCM2JavaGenerator{
	
	String joanaFlowPath = "";
	
	
	
	List<Triplet<String,String,String>> contentsForFolderAndFileNames;
	
	new(){
		generatorClassifier = new PCM2Java4JOANAGeneratorClassifier("");
	}
	
	new(String joanaFlowPath){
		this.joanaFlowPath = joanaFlowPath;
		
		generatorClassifier = new PCM2Java4JOANAGeneratorClassifier(this.joanaFlowPath); 
	}
	
	def List<Triplet<String,String,String>> getContentForFolderAndFileNames(){
		return contentsForFolderAndFileNames;
	}
	
	/**
	 * @inheritDoc
	 * 
	 * Generate a logging document with all Paths to the files
	 */
	override generateAndAddOptionalContents(List<Triplet<String,String,String>> contentsForFolderAndFileNames){
		if(!contentsForFolderAndFileNames.empty){
			this.contentsForFolderAndFileNames = contentsForFolderAndFileNames;
		}	
	}
	

	
	
	
}