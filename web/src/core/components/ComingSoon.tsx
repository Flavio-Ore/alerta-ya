interface ComingSoonProps {
  title: string;
  icon: string;
  description: string;
  dependsOn?: string;
}

const ComingSoon = ({
  title,
  icon,
  description,
  dependsOn,
}: ComingSoonProps) => {
  return (
    <div className="flex-1 overflow-auto p-8 bg-stitch-surface text-stitch-on-surface">
      <div className="max-w-2xl mx-auto mt-20 flex flex-col items-center text-center gap-6">
        <div className="w-20 h-20 rounded-full bg-stitch-surface-container flex items-center justify-center">
          <span className="material-symbols-outlined text-stitch-tertiary text-4xl">
            {icon}
          </span>
        </div>

        <div className="space-y-3">
          <h1 className="text-3xl font-headline font-bold text-white tracking-tight">
            {title}
          </h1>
          <span className="inline-block text-[10px] font-bold uppercase tracking-widest text-stitch-tertiary bg-stitch-tertiary/10 px-3 py-1 rounded">
            Próximamente
          </span>
          <p className="text-sm text-stitch-on-surface-variant leading-relaxed max-w-md mx-auto">
            {description}
          </p>
        </div>

        {dependsOn && (
          <div className="mt-6 p-4 bg-stitch-surface-container-low rounded-xl flex items-start gap-3 text-left">
            <span className="material-symbols-outlined text-stitch-on-surface-variant text-sm mt-0.5">
              info
            </span>
            <div>
              <p className="text-[10px] font-bold uppercase tracking-widest text-stitch-on-surface-variant mb-1">
                Dependencia
              </p>
              <p className="text-xs text-stitch-on-surface">{dependsOn}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ComingSoon;
