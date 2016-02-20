## 3.4.2 (10/25/2015)

* [#314](https://github.com/intridea/hashie/pull/314): Added a `StrictKeyAccess` extension that will raise an error whenever a key is accessed that does not exist in the hash - [@pboling](https://github.com/pboling).
* [#304](https://github.com/intridea/hashie/pull/304): Ensured compatibility of `Hash` extensions with singleton objects - [@regexident](https://github.com/regexident).
* [#306](https://github.com/intridea/hashie/pull/306): Added `Hashie::Extensions::Dash::Coercion` - [@marshall-lee](https://github.com/marshall-lee).
* [#310](https://github.com/intridea/hashie/pull/310): Fixed `Hashie::Extensions::SafeAssignment` bug with private methods - [@marshall-lee](https://github.com/marshall-lee).
* [#313](https://github.com/intridea/hashie/pull/313): Restrict pending spec to only Ruby versions 2.2.0-2.2.2 - [@pboling](https://github.com/pboling).
* [#315](https://github.com/intridea/hashie/pull/315): Default `bin/` scripts: `console` and `setup` - [@pboling](https://github.com/pboling).

## 3.4.2 (6/2/2015)

* [#292](https://github.com/intridea/hashie/pull/292): Removed `Mash#id` and `Mash#type` - [@jrochkind](https://github.com/jrochkind).
* [#297](https://github.com/intridea/hashie/pull/297): Extracted `Trash`'s behavior into a new `Dash::PropertyTranslation` extension - [@michaelherold](https://github.com/michaelherold).

## 3.4.1 (3/31/2015)

* [#269](https://github.com/intridea/hashie/pull/272): Added Hashie::Extensions::DeepLocate - [@msievers](https://github.com/msievers).
* [#270](https://github.com/intridea/hashie/pull/277): Fixed ArgumentError raised when using IndifferentAccess and HashWithIndifferentAccess - [@gardenofwine](https://github.com/gardenofwine).
* [#281](https://github.com/intridea/hashie/pull/281): Added #reverse_merge to Mash to override ActiveSupport's version - [@mgold](https://github.com/mgold).
* [#282](https://github.com/intridea/hashie/pull/282): Fixed coercions in a subclass accumulating in the superclass - [@maxlinc](https://github.com/maxlinc), [@martinstreicher](https://github.com/martinstreicher).

## 3.4.0 (2/02/2015)

* [#271](https://github.com/intridea/hashie/pull/271): Added ability to define defaults based on current hash - [@gregory](https://github.com/gregory).
* [#247](https://github.com/intridea/hashie/pull/247): Fixed #stringify_keys and #symbolize_keys collision with ActiveSupport - [@bartoszkopinski](https://github.com/bartoszkopinski).
* [#249](https://github.com/intridea/hashie/pull/249): SafeAssignment will now also protect hash-style assignments - [@jrochkind](https://github.com/jrochkind).
* [#251](https://github.com/intridea/hashie/pull/251): Added block support to indifferent access #fetch - [@jgraichen](https://github.com/jgraichen).
* [#252](https://github.com/intridea/hashie/pull/252): Added support for conditionally required Hashie::Dash attributes - [@ccashwell](https://github.com/ccashwell).
* [#256](https://github.com/intridea/hashie/pull/256): Inherit key coercions - [@Erol](https://github.com/Erol).
* [#259](https://github.com/intridea/hashie/pull/259): Fixed handling of default proc values in Mash - [@Erol](https://github.com/Erol).
* [#260](https://github.com/intridea/hashie/pull/260): Added block support to Extensions::DeepMerge - [@galathius](https://github.com/galathius).
* [#254](https://github.com/intridea/hashie/pull/254): Added public utility methods for stringify and symbolize keys - [@maxlinc](https://github.com/maxlinc).
* [#261](https://github.com/intridea/hashie/pull/261): Fixed bug where Dash.property modifies argument object - [@d-tw](https://github.com/d-tw).
* [#264](https://github.com/intridea/hashie/pull/264): Methods such as abc? return true/false with Hashie::Extensions::MethodReader - [@Zloy](https://github.com/Zloy).
* [#269](https://github.com/intridea/hashie/pull/269): Add #extractable_options? so ActiveSupport Array#extract_options! can extract it - [@ridiculous](https://github.com/ridiculous).

## 3.3.2 (11/26/2014)

* [#233](https://github.com/intridea/hashie/pull/233): Custom error messages for required properties in Hashie::Dash subclasses - [@joss](https://github.com/joss).
* [#231](https://github.com/intridea/hashie/pull/231): Added support for coercion on class type that inherit from Hash - [@gregory](https://github.com/gregory).
* [#228](https://github.com/intridea/hashie/pull/228): Made Hashie::Extensions::Parsers::YamlErbParser pass template filename to ERB - [@jperville](https://github.com/jperville).
* [#224](https://github.com/intridea/hashie/pull/224): Merging Hashie::Mash now correctly only calls the block on duplicate values - [@amysutedja](https://github.com/amysutedja).
* [#221](https://github.com/intridea/hashie/pull/221): Reduce amount of allocated objects on calls with suffixes in Hashie::Mash - [@kubum](https://github.com/kubum).
* [#245](https://github.com/intridea/hashie/pull/245): Added Hashie::Extensions::MethodAccessWithOverride to autoloads - [@Fritzinger](https://github.com/Fritzinger).

## 3.3.1 (8/26/2014)

* [#183](https://github.com/intridea/hashie/pull/183): Added Mash#load with YAML file support - [@gregory](https://github.com/gregory).
* [#195](https://github.com/intridea/hashie/pull/195): Ensure that the same object is returned after injecting IndifferentAccess - [@michaelherold](https://github.com/michaelherold).
* [#201](https://github.com/intridea/hashie/pull/201): Hashie::Trash transforms can be inherited - [@fobocaster](https://github.com/fobocaster).
* [#189](https://github.com/intridea/hashie/pull/189): Added Rash#fetch - [@medcat](https://github.com/medcat).
* [#200](https://github.com/intridea/hashie/pull/200): Improved coercion: primitives and error handling - [@maxlinc](https://github.com/maxlinc).
* [#204](https://github.com/intridea/hashie/pull/204): Added Hashie::Extensions::MethodOverridingWriter and MethodAccessWithOverride - [@michaelherold](https://github.com/michaelherold).
* [#205](http://github.com/intridea/hashie/pull/205): Added Hashie::Extensions::Mash::SafeAssignment - [@michaelherold](https://github.com/michaelherold).
* [#206](http://github.com/intridea/hashie/pull/206): Fixed stack overflow from repetitively including coercion in subclasses - [@michaelherold](https://github.com/michaelherold).
* [#207](http://github.com/intridea/hashie/pull/207): Fixed inheritance of transformations in Trash - [@fobocaster](https://github.com/fobocaster).
* [#209](http://github.com/intridea/hashie/pull/209): Added Hashie::Extensions::DeepFind - [@michaelherold](https://github.com/michaelherold).
* [#69](https://github.com/intridea/hashie/pull/69): Fixed regression in assigning multiple properties in Hashie::Trash - [@michaelherold](https://github.com/michaelherold), [@einzige](https://github.com/einzige), [@dblock](https://github.com/dblock).

## 3.2.0 (7/10/2014)

* [#164](https://github.com/intridea/hashie/pull/164), [#165](https://github.com/intridea/hashie/pull/165), [#166](https://github.com/intridea/hashie/pull/166): Fixed stack overflow when coercing mashes that contain ActiveSupport::HashWithIndifferentAccess values - [@numinit](https://github.com/numinit), [@kgrz](https://github.com/kgrz).
* [#177](https://github.com/intridea/hashie/pull/177): Added support for coercing enumerables and collections - [@gregory](https://github.com/gregory).
* [#179](https://github.com/intridea/hashie/pull/179): Mash#values_at will convert each key before doing the lookup - [@nahiluhmot](https://github.com/nahiluhmot).
* [#184](https://github.com/intridea/hashie/pull/184): Allow ranges on Rash to match all Numeric types - [@medcat](https://github.com/medcat).
* [#187](https://github.com/intridea/hashie/pull/187): Automatically require version - [@medcat](https://github.com/medcat).
* [#190](https://github.com/intridea/hashie/issues/190): Fixed `coerce_key` with `from` Trash feature and Coercion extension - [@gregory](https://github.com/gregory).
* [#192](https://github.com/intridea/hashie/pull/192): Fixed StringifyKeys#stringify_keys! to recursively stringify keys of embedded ::Hash types - [@dblock](https://github.com/dblock).

## 3.1.0 (6/25/2014)

* [#169](https://github.com/intridea/hashie/pull/169): Hash#to_hash will also convert nested objects that implement to_hash - [@gregory](https://github.com/gregory).
* [#171](https://github.com/intridea/hashie/pull/171): Include Trash and Dash class name when raising `NoMethodError` - [@gregory](https://github.com/gregory).
* [#172](https://github.com/intridea/hashie/pull/172): Added Dash and Trash#update_attributes! - [@gregory](https://github.com/gregory).
* [#173](https://github.com/intridea/hashie/pull/173): Auto include Dash::IndifferentAccess when IndiferentAccess is included in Dash - [@gregory](https://github.com/gregory).
* [#174](https://github.com/intridea/hashie/pull/174): Fixed `from` and `transform_with` Trash features when IndifferentAccess is included - [@gregory](https://github.com/gregory).

## 3.0.0 (6/3/2014)

**Note:** This version introduces several backward incompatible API changes. See [UPGRADING](UPGRADING.md) for details.

* [#150](https://github.com/intridea/hashie/pull/159): Handle nil intermediate object on deep fetch - [@stephenaument](https://github.com/stephenaument).
* [#146](https://github.com/intridea/hashie/issues/146): Mash#respond_to? inconsistent with #method_missing and does not respond to #permitted? - [@dblock](https://github.com/dblock).
* [#152](https://github.com/intridea/hashie/pull/152): Do not convert keys to String in Hashie::Dash and Hashie::Trash, use Hashie::Extensions::Dash::IndifferentAccess to achieve backward compatible behavior - [@dblock](https://github.com/dblock).
* [#152](https://github.com/intridea/hashie/pull/152): Do not automatically stringify keys in Hashie::Hash#to_hash, pass `:stringify_keys` to achieve backward compatible behavior - [@dblock](https://github.com/dblock).
* [#148](https://github.com/intridea/hashie/pull/148): Consolidated Hashie::Hash#stringify_keys implementation - [@dblock](https://github.com/dblock).
* [#149](https://github.com/intridea/hashie/issues/149): Allow IgnoreUndeclared and DeepMerge to be used with undeclared properties - [@jhaesus](https://github.com/jhaesus).

## 2.1.2 (5/12/2014)

* [#169](https://github.com/intridea/hashie/pull/169): Hash#to_hash will also convert nested objects that implement `to_hash` - [@gregory](https://github.com/gregory).

## 2.1.1 (4/12/2014)

* [#144](https://github.com/intridea/hashie/issues/144): Fixed regression invoking `to_hash` with no parameters - [@mbleigh](https://github.com/mbleigh).

## 2.1.0 (4/6/2014)

* [#134](https://github.com/intridea/hashie/pull/134): Add deep_fetch extension for nested access - [@tylerdooling](https://github.com/tylerdooling).
* Removed support for Ruby 1.8.7 - [@dblock](https://github.com/dblock).
* Ruby style now enforced with Rubocop - [@dblock](https://github.com/dblock).
* [#138](https://github.com/intridea/hashie/pull/138): Added Hashie::Rash, a hash whose keys can be regular expressions or ranges - [@epitron](https://github.com/epitron).
* [#131](https://github.com/intridea/hashie/pull/131): Added IgnoreUndeclared, an extension to silently ignore undeclared properties at intialization - [@righi](https://github.com/righi).
* [#136](https://github.com/intridea/hashie/issues/136): Removed Hashie::Extensions::Structure - [@markiz](https://github.com/markiz).
* [#107](https://github.com/intridea/hashie/pull/107): Fixed excessive value conversions, poor performance of deep merge in Hashie::Mash - [@davemitchell](https://github.com/dblock), [@dblock](https://github.com/dblock).
* [#69](https://github.com/intridea/hashie/issues/69): Fixed assigning multiple properties in Hashie::Trash - [@einzige](https://github.com/einzige).
* [#100](https://github.com/intridea/hashie/pull/100): IndifferentAccess#store will respect indifference - [@jrochkind](https://github.com/jrochkind).
* [#103](https://github.com/intridea/hashie/pull/103): Fixed support for Hashie::Dash properties that end in bang - [@thedavemarshall](https://github.com/thedavemarshall).
* [89](https://github.com/intridea/hashie/issues/89): Do not respond to every method with suffix in Hashie::Mash, fixes Rails strong_parameters - [@Maxim-Filimonov](https://github.com/Maxim-Filimonov).
* [#110](https://github.com/intridea/hashie/pull/110): Correctly use Hash#default from Mash#method_missing - [@ryansouza](https://github.com/ryansouza).
* [#120](https://github.com/intridea/hashie/pull/120): Pass options to recursive to_hash calls - [@pwillett](https://github.com/pwillett).
* [#113](https://github.com/intridea/hashie/issues/113): Fixed Hash#merge with Hashie::Dash - [@spencer1248](https://github.com/spencer1248).
* [#99](https://github.com/intridea/hashie/issues/99): Hash#deep_merge raises errors when it encounters integers - [@defsprite](https://github.com/defsprite).
* [#133](https://github.com/intridea/hashie/pull/133): Fixed Hash##to_hash with symbolize_keys - [@mhuggins](https://github.com/mhuggins).
* [#130](https://github.com/intridea/hashie/pull/130): IndifferentAccess now works without MergeInitializer - [@npj](https://github.com/npj).
* [#111](https://github.com/intridea/hashie/issues/111): Trash#translations correctly maps original to translated names - [@artm](https://github.com/artm).
* [#129](https://github.com/intridea/hashie/pull/129): Added Trash#permitted_input_keys and inverse_translations - [@artm](https://github.com/artm).

## 2.0.5

* [#96](https://github.com/intridea/hashie/pull/96): Make coercion work better with non-symbol keys in Hashie::Mash - [@wapcaplet](https://github.com/wapcaplet).

## 2.0.4

* [#04](https://github.com/intridea/hashie/pull/94): Make #fetch method consistent with normal Hash - [@markiz](https://github.com/markiz).
* [#90](https://github.com/intridea/hashie/pull/90): Various doc tweaks - [@craiglittle](https://github.com/craiglittle).

## 2.0.3

* [#88](https://github.com/intridea/hashie/pull/88): Hashie::Mash.new(abc: true).respond_to?(:abc?) works - [@7even](https://github.com/7even).
* [#68](https://github.com/intridea/hashie/pull/68): Fix #replace - [@jimeh](https://github.com/jimeh).

## 2.0.2

* [#85](https://github.com/intridea/hashie/pull/85): adding symbolize_keys back to to_hash - [@cromulus](https://github.com/cromulus).

## 2.0.1

* [#81](https://github.com/intridea/hashie/pull/81): remove Mash#object_id override - [@matschaffer](https://github.com/matschaffer).
* Gem cleanup: removed VERSION, Gemfile.lock [@jch](https://github.com/jch), [@mbleigh](https://github.com/mbleigh).

## 2.0.0

* [#72](https://github.com/intridea/hashie/pull/72): Updated gemspec with license info - [@jordimassaguerpla](https://github.com/jordimassaguerpla).
* [#27](https://github.com/intridea/hashie/pull/27): Initialized with merge coerces values - [@mattfawcett](https://github.com/mattfawcett).
* [#28](https://github.com/intridea/hashie/pull/28): Hashie::Extensions::Coercion coerce_keys takes arguments - [@mattfawcett](https://github.com/mattfawcett).
* [#39](https://github.com/intridea/hashie/pull/39): Trash removes translated values on initialization - [@sleverbor](https://github.com/sleverbor).
* [#66](https://github.com/intridea/hashie/pull/66): Mash#fetch works with symbol or string keys - [@arthwood](https://github.com/arthwood).
* [#49](https://github.com/intridea/hashie/pull/49): Hashie::Hash inherits from ::Hash to avoid ambiguity - [@meh](https://github.com/meh), [@orend](https://github.com/orend).
* [#62](https://github.com/intridea/hashie/pull/62): update respond_to? method signature to match ruby core definition - [@dlupu](https://github.com/dlupu).
* [#41](https://github.com/intridea/hashie/pull/41): DeepMerge extension - [@nashby](https://github.com/nashby).
* [#63](https://github.com/intridea/hashie/pull/63): Dash defaults are dup'ed before assigned - [@ohrite](https://github.com/ohrite).
* [#77](https://github.com/intridea/hashie/pull/77): Remove id, type, and object_id as special allowable keys [@jch](https://github.com/jch).
* [#78](https://github.com/intridea/hashie/pull/78): Merge and update accepts a block - [@jch](https://github.com/jch).
