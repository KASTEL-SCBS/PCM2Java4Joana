package edu.kit.kastel.scbs.pcm2java4joana.cli;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.nio.file.CopyOption;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;

import edu.kit.kastel.scbs.pcm2java4joana.PCM2Java4Joana;

public class PCM2Java4JoanaCommandLineParameters {

	String repositoryPath = "";
	String[] systemPaths = null;
	String destinationPath = "";
	String flowPath = "";
	String workspaceFlowPath = "";
	private List<IFile> resources;
	private List<String> resourcePaths;
	public final static String GENFOLDERNAME = "PCM2Java4JOANAGenerate";
	boolean logGeneratedFiles = false;

	public PCM2Java4JoanaCommandLineParameters(String repositoryPath, String[] systemsPaths, String destinationPath,
			String joanaFlowPath, boolean logGeneratedFiles) {
		this.repositoryPath = repositoryPath;
		this.systemPaths = systemsPaths;
		this.destinationPath = destinationPath;
		this.flowPath = joanaFlowPath;
		resourcePaths = new ArrayList<String>();
		resources = new ArrayList<IFile>();
		resourcePaths.add(repositoryPath);
		resourcePaths.add(joanaFlowPath);
		this.logGeneratedFiles = logGeneratedFiles;

		for (String systemPath : systemsPaths) {
			resourcePaths.add(systemPath);
		}

	}

	public PCM2Java4JoanaCommandLineParameters() {
	}

	public boolean isValid() {
		return !repositoryPath.isBlank() && !flowPath.isBlank() && systemPaths != null
				&& !destinationPath.isBlank();
	}

	public String getRepositoryPath() {
		return repositoryPath;
	}

	public String[] getSystemsPaths() {
		return systemPaths;
	}

	public String getDestinationPath() {
		return destinationPath;
	}

	public String getJoanaFlowPath() {
		return flowPath;
	}

	public List<String> getResourcePaths() {
		return resourcePaths;
	}

	public boolean logGeneratedFiles() {
		return logGeneratedFiles;
	}

	public List<IFile> getFilesOfResourcePaths() {
		String workspaceLocation = ResourcesPlugin.getWorkspace().getRoot().getLocation().toString();

		if (resourcesInitializationRequired()) {
			resources.clear();
			for (String path : resourcePaths) {
				Path targetPath = Paths.get(path);

				IFile workspaceFile = null;

				URI location = null;
				if (targetPath.toFile() != null) {
					location = targetPath.toUri();
				}
				if (!path.contains(workspaceLocation)) {
					IProgressMonitor progressMonitor = new NullProgressMonitor();
					IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
					IProject project = root.getProject(GENFOLDERNAME);

					if (!project.exists()) {
						try {
							project.create(progressMonitor);
						} catch (CoreException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}

					try {
						project.open(progressMonitor);
					} catch (CoreException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}

					Path generationFolderLocation = Paths.get(workspaceLocation, GENFOLDERNAME, "generationFolder");
					File tmpFolder = new File(generationFolderLocation.toAbsolutePath().toString());
					if (!tmpFolder.exists()) {
						tmpFolder.mkdirs();
					}

					String targetFileName = targetPath.getFileName().toString();
					Path destinationFile = Paths.get(generationFolderLocation.toAbsolutePath().toString(),
							targetFileName);

					if (!destinationFile.toFile().exists()) {
						try {
							Files.createFile(destinationFile);
						} catch (IOException e1) {
							// TODO Auto-generated catch block
							System.out.println("Error in Creating file");
						}
					}

					try {
						Files.copy(targetPath, destinationFile, StandardCopyOption.REPLACE_EXISTING);
					} catch (IOException e) {
						// TODO Auto-generated catch block

						System.out.println("Error in copying file ");
						System.out.println("File: " + targetPath);
						System.out.println("File Name: " + targetFileName);
						System.out.println("DestinationFile: " + destinationFile);
						System.out.println("DestinationFile Name: " + destinationFile);
						System.out.println("DestinationFile exists: " + destinationFile.toFile().exists());
					}

					if (destinationFile.toAbsolutePath().toString().endsWith(PCM2Java4Joana.FLOW_FILE_ENDING)) {
						try {
							workspaceFlowPath = destinationFile.toFile().getCanonicalPath();
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
					}

					location = destinationFile.toUri();
				}

				IFile[] files = ResourcesPlugin.getWorkspace().getRoot().findFilesForLocationURI(location);
				if (files.length > 0) {
					workspaceFile = files[0];
					resources.add(workspaceFile);
				}
			}
		}

		return resources;
	}

	private boolean resourcesInitializationRequired() {
		return !(resources.size() == resourcePaths.size());
	}

	public String getWorkspaceFlowPath() {
		return workspaceFlowPath;
	}

}
