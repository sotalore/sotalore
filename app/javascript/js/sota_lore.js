
export default class {
  static pageLoad(onLoad) {
    document.addEventListener("turbo:load", onLoad);
  }
};
