import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class SealedClassGenerator extends Generator {
  var relationsMap = Map<ClassElement, List<ClassElement>>();

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    var buffer = new StringBuffer();
    relationsMap.clear();

    library.allElements
        .where((element) => element is ClassElement)
        .cast<ClassElement>()
        .forEach((element) {
      if (element.hasSealed) {
        relationsMap.putIfAbsent(element, () => []);
      }
    });
      library.allElements
        .where((element) => element is ClassElement)
        .cast<ClassElement>()
        .forEach(buildRelations);

    relationsMap.keys.forEach((sealed) => {
          buffer.write("class Sealed${sealed.thisType.getDisplayString(withNullability: false)}{ "),
          if (relationsMap[sealed]!.isNotEmpty) {
              buffer.write("R when<R>({"),
              relationsMap[sealed]!.asMap().forEach((index, child) => {
                    buffer.write(
                        "@required R Function(${child.thisType.getDisplayString(withNullability: false)}) ${ReCase(child.name).camelCase}"),
                    if (index < relationsMap[sealed]!.length) {buffer.write(",")}
                  }),
              buffer.write("}) {"),
              relationsMap[sealed]!.forEach((child) => {
                    buffer.write("if(this is ${child.thisType.getDisplayString(withNullability: false)}) {"),
                    buffer.write(
                        "return ${ReCase(child.name).camelCase}(this as ${child.thisType.getDisplayString(withNullability: false)}); }")
                  }),
              buffer.write(
                  """throw new Exception('If you got here, probably you forgot to regenerate the classes? Try running flutter packages pub run build_runner build');}"""),
            },
          buffer.write("}")
        });

    return "${buffer.toString()}";
  }

  buildRelations(ClassElement element) {
    if(!element.hasSealed) {
      // Find every relation
      var hasRelation = relationsMap.keys.where((ClassElement sealed) => element.allSupertypes.map((it) => it.getDisplayString(withNullability: false)).contains(sealed.thisType.getDisplayString(withNullability: false)));

      hasRelation.forEach((value) => relationsMap[value]!.add(element));
    }
  }
}
