# Dependency Graph

As part of the elective, we were asked to generate a dependency graph to map out the legacy codebase and the dependencies it relies on.

## Value

Working with a dependency graph has not proved very useful for our group. We don't disagree with the concept, quite the contrary, it can be great for complex systems, where onboarding proves to be difficult, partly because of how massive some systems can be.

## CALMS

_However_, with a legacy codebase this simple, it feels like a frictional, even bureaucratic type of task — something that feels like it belongs in heavier development frameworks and doesn't feel in line with **Lean** in CALMS, at the current state of development.

On top of this, it introduces technical debt by forcing us to learn a toolchain for generating graphs, especially from a codebase written in a language we have never worked with, let alone an old deprecated version of it.

## Conclusion

It adds unnecessary overhead and doesn't provide us with clear functional value, time we'd rather spend on properly converting from Python2 to Ruby and making sure our new codebase is at its best.

![dependencygraph](./imgs/dependency-graph.png)
