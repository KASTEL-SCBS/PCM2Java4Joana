package edu.kit.kastel.scbs.pcm2java4joana.generator

import edu.kit.ipd.sdq.mdsd.pcm2java.generator.PCM2JavaGeneratorClassifier
import org.palladiosimulator.pcm.repository.OperationSignature
import org.eclipse.emf.ecore.resource.Resource
import edu.kit.kastel.scbs.simpleflowmodel4pcm.Simpleflowmodel4pcmPackage
import org.palladiosimulator.pcm.PcmPackage
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.common.util.URI
import java.io.File
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.core.internal.resources.ResourceException
import edu.kit.kastel.scbs.simpleflowmodel4pcm.SignatureIdentification
import org.palladiosimulator.pcm.repository.BasicComponent

import org.palladiosimulator.pcm.repository.Parameter
import java.util.ArrayList
import org.eclipse.internal.xtend.util.Triplet
import java.util.Collection
import org.palladiosimulator.pcm.repository.DataType
import edu.kit.ipd.sdq.mdsd.pcm2java.util.DataTypeUtil
import edu.kit.ipd.sdq.mdsd.pcm2java.util.SignatureUtil
import edu.kit.kastel.scbs.simpleflowmodel4pcm.Flow
import edu.kit.kastel.scbs.simpleflowmodel4pcm.Flows
import edu.kit.kastel.scbs.simpleflowmodel4pcm.Sink
import edu.kit.kastel.scbs.simpleflowmodel4pcm.GenericSink
import edu.kit.kastel.scbs.simpleflowmodel4pcm.SignatureSink
import edu.kit.kastel.scbs.simpleflowmodel4pcm.ParameterSink
import edu.kit.kastel.scbs.simpleflowmodel4pcm.ParameterIdentification

class PCM2Java4JOANAGeneratorClassifier extends PCM2JavaGeneratorClassifier {

	enum AnnotationKind {
		SOURCE,
		DECLASSIFICATION,
		SINK
	}

	Flows flows;
	var flowPath = "";
	// TODO: Hotfix, fix later correctly when IDs for sinks and sources are available
	OperationSignature currentOperationSignature;
	var toggleComplexTags = true;

	new(String flowPath) {
		this.flowPath = flowPath;
	}

	private def loadJoanaRoot() {

		if (flows !== null) {
			return;
		}

		var registry = Resource.Factory.Registry.INSTANCE;
		var map = registry.getExtensionToFactoryMap();

		Simpleflowmodel4pcmPackage.eINSTANCE.eClass();
		PcmPackage.eINSTANCE.eClass();

		map.put("joanaflow4palladio", new XMIResourceFactoryImpl());
		map.put("repository", new XMIResourceFactoryImpl());

		var resSet = new ResourceSetImpl();
		try {
			var absoluteFile = new File(flowPath).absolutePath
			var uri = URI.createFileURI(absoluteFile);
			var resource = resSet.getResource(uri, true);
			EcoreUtil.resolveAll(resource);
			resource.load(null);
			flows = resource.getContents().get(0) as Flows;
		} catch (ResourceException e) {
			System.out.println("Resource not Found")
		}
	}

	override generateMethodDeclarationWithoutSemicolon(OperationSignature operationSignature) {

		loadJoanaRoot();
		if (flows !== null) {
			currentOperationSignature = operationSignature;
			val returnType = operationSignature.returnType__OperationSignature.generateReturnType
			val methodName = SignatureUtil.getMethodName(operationSignature)
			val joanaFlowSpec = flows.flow;
			val sourceFlow = joanaFlowSpec.getSourceFlowsContainingComponentAndOperationSignature(operationSignature);
			val sinkFlow = joanaFlowSpec.getSinkFlowsContainingComponentAndOperationSignature(operationSignature);

			val parameterDeclarations = '''«FOR parameter : operationSignature.parameters__OperationSignature SEPARATOR ', '»«parameter.generateAnnotationsForParameter(sourceFlow, sinkFlow)»«DataTypeUtil.getClassNameOfDataType(parameter.dataType__Parameter)» «parameter.getParameterName»«ENDFOR»'''

			currentOperationSignature = null;

			return '''«returnType» «methodName»(«parameterDeclarations»)''';
		} else {
			return super.generateMethodDeclarationWithoutSemicolon(operationSignature);
		}
	}

	override generateCommentsForMethod(OperationSignature signature) {

		loadJoanaRoot();

		if (flows !== null) {
			val joanaFlowSpec = flows.flow;
			currentOperationSignature = signature;
			val sourceFlow = joanaFlowSpec.getSourceFlowsContainingComponentAndOperationSignature(signature);
			val sinkFlow = joanaFlowSpec.getSinkFlowsContainingComponentAndOperationSignature(signature);
			val entryPointAnnotations = generateEntryPointMethodAnnotation(signature);
			val flowAnnotations = generateMethodFlowAnnotationForSignature(sourceFlow, sinkFlow, signature);

			val commentaries = entryPointAnnotations + flowAnnotations;

			currentOperationSignature = null;
			return commentaries;
		} else
			return ""
	}

	def String generateMethodFlowAnnotationForSignature(Iterable<Flow> sourceFlow, Iterable<Flow> sinkFlow,
		OperationSignature signature) {

		if (bc === null) {
			return "";
		}

		var sourceFlowsWithoutParameters = sourceFlow.getSourceFlowsWithoutParameters(signature);
		var sinkFlowsWithoutParameters = sinkFlow.getSinkFlowsWithoutParameters(signature);

		return generateAnnotationsForFlows(sourceFlowsWithoutParameters, sinkFlowsWithoutParameters);
	}

	def String generateEntryPointMethodAnnotation(OperationSignature signature) {

		var entryFlows = getSourceFlowsContainingComponentAndOperationSignature(flows.flow, signature);

		return entryPointStringAnnotation(entryFlows);
	}

	def Iterable<Flow> getSourceFlowsContainingComponentAndOperationSignature(Iterable<Flow> flows,
		OperationSignature signature) {

		var sourcesContainingFlows = new ArrayList<Flow>();

		for (flow : flows) {
			var source = flow.source;
			if (source instanceof SignatureIdentification) {
				if (source.containsComponentAndOperationSignature(super.bc, signature)) {
					sourcesContainingFlows.add(flow);
				}
			}
		}

		return sourcesContainingFlows;
	}

	def Iterable<Flow> getSinkFlowsContainingComponentAndOperationSignature(Iterable<Flow> flows,
		OperationSignature signature) {
		return flows.filter [ flow |
			flow.sink.parameterSinks.exists [ sink |
				(sink as SignatureIdentification).containsComponentAndOperationSignature(super.bc, signature)
			]
		];
	}

	def boolean containsComponentAndOperationSignature(SignatureIdentification identification, BasicComponent bc,
		OperationSignature signature) {
		if(bc === null) return false;

		return identification.containsComponent(bc) && identification.containsOperationSignature(signature);
	}

	def boolean containsOperationSignature(SignatureIdentification identification, OperationSignature signature) {
		return identification.signature.id.equals(signature.id);
	}

	def boolean containsComponent(SignatureIdentification identification, BasicComponent component) {
		return identification.component.id.equals(component.id);
	}

	def Iterable<Sink> getParameterSinks(Iterable<Sink> sinks) {
		return sinks.filter[sink|sink instanceof ParameterSink]
	}

	def Iterable<Sink> getSignatureSinks(Iterable<Sink> sinks) {
		return sinks.filter[sink|sink instanceof SignatureSink]
	}

	def Iterable<Sink> getGenericSinks(Iterable<Sink> sinks) {
		return sinks.filter[sink|sink instanceof GenericSink];
	}

	def Iterable<Flow> getSourceFlowsWithoutParameters(Iterable<Flow> flows, OperationSignature signature) {

		var sourcesContainingFlows = new ArrayList();

		for (flow : flows) {
			var source = flow.source;
			if (!(source instanceof ParameterIdentification)) {
				sourcesContainingFlows.add(flow);
			}
		}
		
		return sourcesContainingFlows;
	}

	def Iterable<Flow> getSinkFlowsWithoutParameters(Iterable<Flow> flows, OperationSignature signature) {
		return flows.filter [ flow |
			flow.sink.parameterSinks.exists [ sink |
				(sink as ParameterIdentification).containsNoParametersForOperationSignature(signature)
			]
		];
	}

	def boolean containsNoParametersForOperationSignature(ParameterIdentification identification,
		OperationSignature signature) {
		return (identification.parameter === null || identification.parameter.size == 0) &&
			identification.containsOperationSignature(signature);
	}

	def String generateAnnotationsForParameter(Parameter parameter, Iterable<Flow> sourceFlows,
		Iterable<Flow> sinkFlows) {

		if (super.bc === null) {
			return "";
		}

		val sourceFlowsContainingParameter = parameter.getSourceFlowsContainingParameter(sourceFlows);
		val sinkFlowsContainingParameter = parameter.getSinkFlowsContainingParameter(sinkFlows);

		return generateAnnotationsForFlows(sourceFlowsContainingParameter, sinkFlowsContainingParameter);
	}

	def String generateAnnotationsForFlows(Iterable<Flow> sourceFlows, Iterable<Flow> sinkFlows) {
		return sourceFlows.generateSourceStringAnnotation + sinkFlows.generateSinkStringAnnotation;
	}

	def String entryPointStringAnnotation(Iterable<Flow> entryPointFlows) {

		var entryPointAnnotation = "";

		for (entryPointFlow : entryPointFlows) {

			for (sourceTag : entryPointFlow.calculateSourceTags) {
				entryPointAnnotation += "@EntryPoint(tag=" + '"' + sourceTag + '"' + ") \n";
			}
		}

		return entryPointAnnotation;
	}

	def String generateClassSinkAnnotationForFlow(Iterable<Sink> sinks) {

		if (sinks.size == 0) {
			return "";
		}

		var classSinksAnnotation = "";

		for (sink : sinks) {

			if (sink instanceof GenericSink) {
				classSinksAnnotation += "@ClassSink(" + sink.targetDescription + ") ";
			}
		}

		return classSinksAnnotation + "\n";
	}

	def String generateSourceStringAnnotation(Iterable<Flow> sourceFlows) {

		if (sourceFlows === null || sourceFlows.size == 0) {
			return "";
		}

		return "@Source(tags=" + sourceFlows.foldIDsForFlows(AnnotationKind.SOURCE) + ")";
	}

	def String generateSinkStringAnnotation(Iterable<Flow> sinkFlows) {
		if (sinkFlows.size == 0) {
			return "";
		}
		return "@Sink(tags=" + sinkFlows.foldIDsForFlows(AnnotationKind.SINK) + ")";
	}

	def String foldIDsForFlows(Iterable<Flow> flows, AnnotationKind kind) {
		if (flows.size == 0) {
			return "";
		}

		var frontBracket = "";
		var rearBracket = "";

		var tags = flows.map[flow|flow.calculateTags(kind)].flatten;

		if (tags.size != 1) {
			frontBracket = "{";
			rearBracket = "}"
		}

		return frontBracket + tags.joinTags() + rearBracket;
	}

	def Iterable<Flow> getSinkFlowsContainingParameter(Parameter parameter, Iterable<Flow> flows) {
		return flows.filter [ flow |
			flow.sink.parameterSinks.exists [ sink |
				(sink as ParameterIdentification).identificationContainsParameter(parameter)
			]
		]
	}

	def Iterable<Flow> getSourceFlowsContainingParameter(Parameter parameter, Iterable<Flow> flows) {

		var result = new ArrayList<Flow>();

		for (flow : flows) {
			var source = flow.source;

			if (source instanceof ParameterIdentification) {
				if (source.identificationContainsParameter(parameter)) {
					result.add(flow);
				}
			}

		}

		return result;
	}

	def boolean identificationContainsParameter(ParameterIdentification identification, Parameter parameter) {
		return identification.parameter.exists[toCompare|toCompare.parameterEquality(parameter)];
	}

	def boolean parameterEquality(Parameter toCompare, Parameter compareAgainst) {
		return toCompare.parameterName.equals(compareAgainst.parameterName) &&
			toCompare.operationSignature__Parameter.id.equals(compareAgainst.operationSignature__Parameter.id);
	}

	def String reduceFlowsToCommaseparatedIdStrings(Iterable<Flow> flows, AnnotationKind kind) {

		return flows.join(", ", [flow|flow.putTagInQuotes]);
	}

	def String joinTags(Iterable<String> tags) {
		return tags.join(", ", [tag|tag.putInQuotes]);
	}

	def Iterable<String> parseFlowsToFlowIDs(Iterable<Flow> flows) {
		return flows.map[flow|flow.putTagInQuotes];
	}

	def Collection<String> calculateTags(Flow flow, AnnotationKind kind) {
		if (kind.equals(AnnotationKind.SOURCE)) {
			return calculateSourceTags(flow);
		} else if (kind.equals(AnnotationKind.SINK)) {
			return calculateSinkTags(flow);
		}

		return new ArrayList<String>();
	}

	def Collection<String> calculateSourceTags(Flow flow) {
		var tags = new ArrayList<String>();

		var sourceId = "";

		var source = flow.source
		if (source instanceof SignatureIdentification) {
			if (source.containsComponentAndOperationSignature(super.bc, currentOperationSignature)) {
				sourceId = currentOperationSignature.id;
			}

			if (sourceId.blank) {
				System.out.println("Uhoh, source not found in flow");
				return tags;
			}

			for (sink : flow.sink) {
				if (sink instanceof ParameterSink) {
					if (!sink.signature.eIsProxy) {
						tags.add(flow.id + "#" + sourceId + "#" + sink.signature.id);
					}
				}
			}
		}
		return tags;
	}

	def Collection<String> calculateSinkTags(Flow flow) {
		var tags = new ArrayList<String>();
		var flowId = flow.id;
		var source = flow.source
		if (source instanceof SignatureIdentification) {
			var sourceId = source.signature.id;
			var sinkId = "";

			for (sink : flow.sink) {
				if (sink instanceof ParameterSink) {
					if (sink.containsComponentAndOperationSignature(super.bc, currentOperationSignature)) {
						sinkId = sink.signature.id;
					}
				}
			}

			if (sinkId.empty) {
				System.out.println("Uhoh, sink not found in flow");
				return tags;
			}

			tags.add(flowId + "#" + sourceId + "#" + sinkId);
		}
		return tags;
	}

	def String putTagInQuotes(Flow flow) {
		return "\"" + flow.id + "\"";
	}

	def String foldToCommaseparated(String a, String b) {
		return a + ", " + b;
	}

	def String generateReturnType(DataType dataType) {
		if (dataType !== null) {
			return DataTypeUtil.getClassNameOfDataType(dataType)
		}
		return "void"
	}

	def String putInQuotes(String string) {
		return "\"" + string + "\"";
	}
}
