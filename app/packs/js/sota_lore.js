
export default class {
  static pageLoad(onLoad) {
    document.addEventListener("turbolinks:load", onLoad);
  }
};
