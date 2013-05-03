.pragma library

Date.prototype.addHours = function(h){
    this.setHours(this.getHours() + h);
    return this;
}
