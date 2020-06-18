package edu.kit.kastel.scbs.pcm2java4joana.cli;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.Options;



public class PCM2Java4JoanaCliHandler {

	
	public static final String PCM_REPOSITORIES = "repositoriespaths";
	public static final String PCM_SYSTEMS = "systemspaths";
	public static final String GENERATION_LOGGING = "genlog";
	public static final String FLOWS = "simpleflowmodelpath";
	public static final String DESTINATION_FOLDER_PATH = "destinationfolder";
	

	public Options getOptions() {
		Options options = new Options();
		Option repositoriesOption = OptionBuilder.withArgName(PCM_REPOSITORIES).hasArg(true).withDescription("File that contains the Editor model").isRequired().create(PCM_REPOSITORIES);
		Option systemsOption = OptionBuilder.withArgName(PCM_SYSTEMS).withDescription("The Path the Models shall be generated into").hasArgs().create(PCM_SYSTEMS);
		Option genlogPathOption = OptionBuilder.withArgName(GENERATION_LOGGING).withDescription("Determines wether adversaries should be considered in input or output").hasArg(false).create(GENERATION_LOGGING);
		Option joanaFlowOption = OptionBuilder.withArgName(FLOWS).withDescription("Specifies that a JOANA Flow Model should be generated").hasArg(true).isRequired().create(FLOWS);
		Option genDestinationOption = OptionBuilder.withArgName(DESTINATION_FOLDER_PATH).withDescription("Specifies the destination the generate should be copied to").hasArg().isRequired().create(DESTINATION_FOLDER_PATH);
		
		
		options.addOption(repositoriesOption);
		options.addOption(systemsOption);
		options.addOption(genlogPathOption);
		options.addOption(joanaFlowOption);
		options.addOption(genDestinationOption);
		
		return options;
	}
	
	public PCM2Java4JoanaCommandLineParameters interrogateCommandLine(CommandLine cmd) {
		
		if(cmd == null) {
			return new PCM2Java4JoanaCommandLineParameters();
		}
		
		String repositoryPath = "";
		String[] systemPaths = null;
		String destinationPath = "";
		String joanaFlowPath = "";
		
		if(cmd.hasOption(PCM_REPOSITORIES)) {
			repositoryPath = cmd.getOptionValue(PCM_REPOSITORIES);
		} else {
			System.out.println("PCM Repository Path not provided");
		}
		
		if(cmd.hasOption(PCM_SYSTEMS)) {
			systemPaths = cmd.getOptionValues(PCM_SYSTEMS);
		} else {
			System.out.println("No Systems Provided not provided");
			systemPaths = new String[0];
		}
		
		if(cmd.hasOption(DESTINATION_FOLDER_PATH)) {
			destinationPath = cmd.getOptionValue(DESTINATION_FOLDER_PATH);
		} else {
			System.out.println("No Destination Folder provided");
		}
		
		if(cmd.hasOption(FLOWS)) {
			joanaFlowPath = cmd.getOptionValue(FLOWS);
		}
		
		boolean generationLogging = cmd.hasOption(GENERATION_LOGGING);
		
		
		return new PCM2Java4JoanaCommandLineParameters(repositoryPath, systemPaths, destinationPath, joanaFlowPath, generationLogging);
	}
	
}
