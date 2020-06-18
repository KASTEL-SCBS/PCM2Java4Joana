package edu.kit.kastel.scbs.pcm2java4joana.cli;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;



public class PCM2Java4JoanaCLI {
	PCM2Java4JoanaCliHandler handler;
	
	public PCM2Java4JoanaCLI() {
		handler = new PCM2Java4JoanaCliHandler();
	}

	private CommandLine parseInput(Options options, String[] args) throws ParseException {
		CommandLineParser parser = new BasicParser();
		return parser.parse(options, args);
	}
	
	public PCM2Java4JoanaCommandLineParameters interrogateCommandLine(String[] args) {
		Options options = handler.getOptions();
		CommandLine cmd = null;
		try {
			cmd = parseInput(options, args);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return handler.interrogateCommandLine(cmd);
	}
}
