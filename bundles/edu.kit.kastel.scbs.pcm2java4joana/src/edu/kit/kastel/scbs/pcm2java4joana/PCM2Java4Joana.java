package edu.kit.kastel.scbs.pcm2java4joana;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.internal.xtend.util.Triplet;

import edu.kit.ipd.sdq.mdsd.ecore2txt.util.Ecore2TxtUtil;
import edu.kit.ipd.sdq.mdsd.pcm2java.generator.PCM2JavaGeneratorModule;
import edu.kit.kastel.scbs.pcm2java4joana.cli.PCM2Java4JoanaCLI;
import edu.kit.kastel.scbs.pcm2java4joana.cli.PCM2Java4JoanaCommandLineParameters;
import edu.kit.kastel.scbs.pcm2java4joana.generator.PCM2Java4JOANAGenerator;


public class PCM2Java4Joana implements IApplication {

	public final static String FLOW_FILE_ENDING = "simpleflowmodel4pcm";
	
	@Override
	public void stop() {
		// TODO Auto-generated method stub
		
	}
	
	public static void main(String[] args) {
		
		PCM2Java4JoanaCommandLineParameters cliParameters =  new PCM2Java4JoanaCLI().interrogateCommandLine(args);
		
		if(cliParameters.isValid()) {
			Ecore2TxtUtil.generateFromSelectedFilesInFolder(cliParameters.getFilesOfResourcePaths(), new PCM2JavaGeneratorModule(), new PCM2Java4JOANAGenerator(cliParameters.getWorkspaceFlowPath()), false, true);
		}  else {
			System.out.println("Error in CLI");
		}
		
		System.out.println("Done");
	}
	
	@Override
	public Object start(IApplicationContext context) throws Exception {
		Map<?, ?> contextArgs = context.getArguments();
		String[] appArgs = (String[]) contextArgs.get("application.args");
		
			System.out.println(System.getProperty("user.dir"));
			PCM2Java4JoanaCommandLineParameters cliParameters = new PCM2Java4JoanaCLI().interrogateCommandLine(appArgs);
			
			cliParameters.getFilesOfResourcePaths();
			
			PCM2Java4JOANAGenerator generator = new PCM2Java4JOANAGenerator(cliParameters.getWorkspaceFlowPath());
			
			if(cliParameters.isValid()) {
				Ecore2TxtUtil.generateFromSelectedFilesInFolder(cliParameters.getFilesOfResourcePaths(), new PCM2JavaGeneratorModule(), generator, false, true);
			} else {
				System.out.println("Error in CLI");
				System.exit(42);
				return 42;
			}
		
			moveFiles(cliParameters.getDestinationPath(), generator.getContentForFolderAndFileNames(), cliParameters.logGeneratedFiles());
	
		System.out.println("Done");
		return IApplication.EXIT_OK;
	}
	
	public void moveFiles(String destination, List<Triplet<String,String,String>> content, boolean loggingGenerationLocations) throws IOException {
		String workspaceLocation = ResourcesPlugin.getWorkspace().getRoot().getLocation().toString();
		String baseLocation = workspaceLocation + File.separatorChar + PCM2Java4JoanaCommandLineParameters.GENFOLDERNAME;
		
		
		StringBuffer stringBuffer = new StringBuffer();
		
		
		
		
			for(Triplet<String,String,String> generated : content) {
				
				Path sourceLocation = Paths.get(baseLocation, generated.getSecond(), generated.getThird());
				Path targetLocation = Paths.get(destination, generated.getSecond(), generated.getThird());
				File generateFile = new File(sourceLocation.toUri()); 
				File target = new File (targetLocation.toUri());
				
				target.getParentFile().mkdirs();
				
				if(!target.exists()) {
				
						target.createNewFile();
					
				}
				
				
				Files.copy(generateFile.toPath(), target.toPath(), StandardCopyOption.REPLACE_EXISTING);
				
				
				generateFile.delete();
				
				stringBuffer.append(targetLocation + "\n");
				
			}
			
			if(!stringBuffer.toString().isBlank() && loggingGenerationLocations) {
				File logFile = new File(destination + File.separatorChar + "GeneratedPathsLogFile.txt");
				if(!logFile.exists()){
					logFile.getParentFile().mkdirs();
					try {
						logFile.createNewFile();
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
				
				
				try {
					BufferedWriter writer = new BufferedWriter(new FileWriter(logFile));
					writer.write(stringBuffer.toString());
					writer.close();
				} catch (IOException e) {
					e.printStackTrace();
				} 
				
			}
			
		}
	
	
	public void removeTemporaryContent() {
		//TODO Implement tmp genfolder cleanup
		
	}

}
