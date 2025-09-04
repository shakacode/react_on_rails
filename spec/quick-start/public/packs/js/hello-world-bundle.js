"use strict";
(self["webpackChunkapp"] = self["webpackChunkapp"] || []).push([["hello-world-bundle"],{

/***/ "./app/javascript/bundles/HelloWorld/components/HelloWorld.jsx":
/*!*********************************************************************!*\
  !*** ./app/javascript/bundles/HelloWorld/components/HelloWorld.jsx ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var prop_types__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! prop-types */ "./node_modules/prop-types/index.js");
/* harmony import */ var prop_types__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(prop_types__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! react */ "./node_modules/react/index.js");
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var _HelloWorld_module_css__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./HelloWorld.module.css */ "./app/javascript/bundles/HelloWorld/components/HelloWorld.module.css");
var _jsxFileName = "/Users/justin/shakacode/react-on-rails/react_on_rails/spec/quick-start/app/javascript/bundles/HelloWorld/components/HelloWorld.jsx";



const HelloWorld = props => {
  const [name, setName] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(props.name);
  return /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("div", {
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 9,
      columnNumber: 5
    }
  }, /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("h3", {
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 10,
      columnNumber: 7
    }
  }, "Hello, ", name, "!"), /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("hr", {
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 11,
      columnNumber: 7
    }
  }), /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("form", {
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 12,
      columnNumber: 7
    }
  }, /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("label", {
    className: _HelloWorld_module_css__WEBPACK_IMPORTED_MODULE_2__.bright,
    htmlFor: "name",
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 13,
      columnNumber: 9
    }
  }, "Say hello to:", /*#__PURE__*/react__WEBPACK_IMPORTED_MODULE_1___default().createElement("input", {
    id: "name",
    type: "text",
    value: name,
    onChange: e => setName(e.target.value),
    __self: undefined,
    __source: {
      fileName: _jsxFileName,
      lineNumber: 15,
      columnNumber: 11
    }
  }))));
};
HelloWorld.propTypes = {
  name: (prop_types__WEBPACK_IMPORTED_MODULE_0___default().string).isRequired // this is passed from the Rails view
};
/* harmony default export */ __webpack_exports__["default"] = (HelloWorld);

/***/ }),

/***/ "./app/javascript/bundles/HelloWorld/components/HelloWorld.module.css":
/*!****************************************************************************!*\
  !*** ./app/javascript/bundles/HelloWorld/components/HelloWorld.module.css ***!
  \****************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   bright: function() { return /* binding */ _1; }
/* harmony export */ });
// extracted by mini-css-extract-plugin
var _1 = "KUWOdYZ4Lk42k3lvLUcM";



/***/ }),

/***/ "./app/javascript/packs/hello-world-bundle.js":
/*!****************************************************!*\
  !*** ./app/javascript/packs/hello-world-bundle.js ***!
  \****************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var react_on_rails_client__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! react-on-rails/client */ "./node_modules/react-on-rails/node_package/lib/ReactOnRails.client.js");
/* harmony import */ var _bundles_HelloWorld_components_HelloWorld__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ../bundles/HelloWorld/components/HelloWorld */ "./app/javascript/bundles/HelloWorld/components/HelloWorld.jsx");



// This is how react_on_rails can see the HelloWorld in the browser.
react_on_rails_client__WEBPACK_IMPORTED_MODULE_0__["default"].register({
  HelloWorld: _bundles_HelloWorld_components_HelloWorld__WEBPACK_IMPORTED_MODULE_1__["default"]
});

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_prop-types_index_js-node_modules_react-on-rails_node_package_lib_ReactOn-093821"], function() { return __webpack_exec__("./app/javascript/packs/hello-world-bundle.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=hello-world-bundle.js.map